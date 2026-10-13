"""전체 실행: python run.py / 한 문항: python run.py 9"""
import argparse
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def show_rows(db, sql, output):
    cursor = db.execute(sql)
    output.append(' | '.join(column[0] for column in cursor.description))
    rows = cursor.fetchall()
    for row in rows:
        output.append(' | '.join('NULL' if value is None else str(value) for value in row))
    output.append(f'결과: {len(rows)}행')


def main():
    parser = argparse.ArgumentParser(description='SQL 전체 또는 한 문항을 새 샘플에서 실행')
    parser.add_argument('question', nargs='?', type=int, choices=range(1, 16),
                        help='실행할 문항 번호 1~15. 생략하면 전체 실행')
    selected = parser.parse_args().question
    output = ['도서 대여 SQL 실습 결과', '매번 동일한 샘플로 시작합니다.\n']
    # 새 DB에서 먼저 실행하므로 기존 실습 DB는 SQL 실행 실패 시 바뀌지 않는다.
    with sqlite3.connect(':memory:') as db:
        db.execute('PRAGMA foreign_keys = ON')
        db.executescript((ROOT / 'schema.sql').read_text(encoding='utf-8'))
        db.executescript((ROOT / 'seed.sql').read_text(encoding='utf-8'))
        tables = ['category', 'book', 'member', 'rental']
        output.append('[샘플 데이터와 PK 확인]')
        for table in tables:
            count = db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
            has_pk = any(column[5] for column in db.execute(f'PRAGMA table_info({table})'))
            if count < 10 or not has_pk:
                raise ValueError(f'{table}: 최소 10행/PK 조건을 확인하세요.')
            output.append(f'{table}: {count}행, PK 확인')

        output.append('\n[제약조건 확인: 실패해야 정상]')
        invalid_inputs = [
            ('FK: 없는 회원 참조', "INSERT INTO rental VALUES (99, 999, 1, '2026-10-13', NULL)"),
            ('FK: 없는 분류 참조', "INSERT INTO book VALUES (99, 999, '잘못된 책', 1000)"),
            ('NOT NULL: 제목 누락', 'INSERT INTO book VALUES (99, 1, NULL, 1000)'),
            ('UNIQUE: 이메일 중복', "INSERT INTO member VALUES (99, '중복 회원', 'member01@example.com')"),
        ]
        for label, sql in invalid_inputs:
            db.execute('SAVEPOINT constraint_check')
            try:
                db.execute(sql)
            except sqlite3.IntegrityError as error:
                output.append(f'{label} → 차단 확인: {error}')
            else:
                raise ValueError(f'{label}: 잘못된 입력이 허용됐습니다.')
            finally:
                db.execute('ROLLBACK TO constraint_check')
                db.execute('RELEASE constraint_check')

        text = (ROOT / 'queries.sql').read_text(encoding='utf-8')
        queries = re.findall(r'-- Q(\d{2}): ([^\n]+)\n(.*?)(?=\n-- Q\d{2}:|\Z)', text, re.S)
        if [number for number, _, _ in queries] != [f'{n:02}' for n in range(1, 16)]:
            raise ValueError('queries.sql에 Q01~Q15를 순서대로 작성하세요.')
        for number, description, sql in queries:
            if selected is not None and int(number) != selected:
                continue
            # 코드 아래의 결과 주석은 실행 대상에서 제외한다.
            sql = sql.split('-- 실행 결과 시작', 1)[0].strip()
            output.extend([f'\n[Q{number}] {description}', sql.strip()])
            if number in ('13', '14'):
                target_id = 12 if number == '13' else 16
                output.append('변경 전:')
                show_rows(db, f'SELECT * FROM rental WHERE id = {target_id}', output)
                cursor = db.execute(sql)
                output.append(f'변경: {cursor.rowcount}행')
                output.append('변경 후:')
                show_rows(db, f'SELECT * FROM rental WHERE id = {target_id}', output)
            elif number == '15':
                db.execute(sql)
                show_rows(db, "SELECT name, sql FROM sqlite_master WHERE type = 'index' AND name = 'idx_rental_member_id'", output)
                show_rows(db, 'EXPLAIN QUERY PLAN SELECT * FROM rental WHERE member_id = 1', output)
            else:
                show_rows(db, sql, output)

        if db.execute('PRAGMA foreign_key_check').fetchall():
            raise ValueError('FK 무결성 검사에 실패했습니다.')
        output.append('\n[최종 데이터 수]')
        for table in tables:
            count = db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
            if count < 10:
                raise ValueError(f'{table}: 수정/삭제 후 최소 10행 조건을 확인하세요.')
            output.append(f'{table}: {count}행')
        db.commit()
        if selected is None:
            with sqlite3.connect(ROOT / 'library.db') as saved:
                db.backup(saved)

    report = '\n'.join(output) + '\n'
    if selected is None:
        results = ROOT / 'results'
        results.mkdir(exist_ok=True)
        (results / 'query_results.txt').write_text(report, encoding='utf-8')
    print(report)
    print('실행 완료. queries.sql의 기존 결과 주석은 변경하지 않습니다.')
    if selected is not None:
        print('개별 문항은 새 샘플에서 실행했습니다. 저장된 library.db는 바꾸지 않습니다.')


if __name__ == '__main__':
    try:
        main()
    except (sqlite3.Error, OSError, ValueError) as error:
        print(f'[오류] {error}\n[힌트] SQL 파일, 폴더 권한, DB를 열고 있는 프로그램을 확인하세요.')
        raise SystemExit(1)

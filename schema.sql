-- 대상 DB: SQLite
-- 문자열은 SQLite가 지원하는 TEXT 타입을 사용한다. TEXT는 SQLite 전용 타입은 아니다.
-- 날짜는 YYYY-MM-DD 형식의 TEXT로 저장한다.
-- 다른 DB로 옮길 때는 자료형과 날짜 처리 방식을 확인해야 한다.

-- SQLite 전용: 이 연결에서 외래키 제약 검사를 활성화한다. 연결마다 설정해야 한다.
PRAGMA foreign_keys = ON;

CREATE TABLE category (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE book (
    id INTEGER PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES category(id),
    title TEXT NOT NULL,
    price INTEGER NOT NULL CHECK (price > 0)
);

CREATE TABLE member (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

CREATE TABLE rental (
    id INTEGER PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES member(id),
    book_id INTEGER NOT NULL REFERENCES book(id),
    -- SQLite는 별도 DATE 저장 타입 대신 TEXT로 ISO 날짜를 저장한다.
    rented_at TEXT NOT NULL,
    returned_at TEXT,
    CHECK (returned_at IS NULL OR returned_at >= rented_at)
);

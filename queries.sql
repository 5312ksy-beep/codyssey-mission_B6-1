-- Q01: 기본 조회 - 18,000원 이상인 책을 찾는다.
SELECT id, title, price FROM book WHERE price >= 18000 ORDER BY id;

-- Q02: 기본 조회 - 비싼 책부터 상위 3권을 확인한다.
SELECT title, price FROM book ORDER BY price DESC, id LIMIT 3;

-- Q03: 기본 조회 - 제목에 'SQL'이 포함된 책을 찾는다.
SELECT id, title FROM book WHERE title LIKE '%SQL%' ORDER BY id;

-- Q04: 기본 조회 - 아직 반납하지 않은 대여를 최신순으로 확인한다.
SELECT id, member_id, book_id, rented_at FROM rental
WHERE returned_at IS NULL ORDER BY rented_at DESC, id DESC;

-- Q05: INNER JOIN - 모든 책에 분류 이름을 붙여 확인한다.
SELECT b.title, c.name AS category_name FROM book AS b
INNER JOIN category AS c ON b.category_id = c.id ORDER BY b.id;

-- Q06: INNER JOIN - 회원 이름과 그 회원의 대여 기록을 연결한다.
SELECT m.id AS member_id, m.name, r.id AS rental_id, r.rented_at
FROM member AS m INNER JOIN rental AS r ON m.id = r.member_id
ORDER BY m.id, r.id;

-- Q07: INNER JOIN - 미반납 대여에 회원 이름과 도서 제목을 붙인다.
SELECT r.id, m.name, b.title, r.rented_at FROM rental AS r
INNER JOIN member AS m ON r.member_id = m.id
INNER JOIN book AS b ON r.book_id = b.id
WHERE r.returned_at IS NULL ORDER BY r.id;

-- Q08: LEFT JOIN - 대여하지 않은 회원도 포함해 모든 회원을 확인한다.
SELECT m.id AS member_id, m.name, r.id AS rental_id
FROM member AS m LEFT JOIN rental AS r ON m.id = r.member_id
ORDER BY m.id, r.id;

-- Q09: 집계 - 회원별 대여 횟수를 구한다. COUNT(r.id)는 NULL을 세지 않는다.
SELECT m.id, m.name, COUNT(r.id) AS rental_count
FROM member AS m LEFT JOIN rental AS r ON m.id = r.member_id
GROUP BY m.id, m.name ORDER BY rental_count DESC, m.id;

-- Q10: 집계 - 분류별 도서 수와 도서 가격 합계를 확인한다. 매출을 뜻하지 않는다.
SELECT c.id, c.name, COUNT(b.id) AS book_count, SUM(b.price) AS total_book_price
FROM category AS c INNER JOIN book AS b ON c.id = b.category_id
GROUP BY c.id, c.name ORDER BY c.id;

-- Q11: 집계 - 분류별 도서 평균 가격을 구한다.
SELECT c.id, c.name, ROUND(AVG(b.price), 2) AS average_price
FROM category AS c INNER JOIN book AS b ON c.id = b.category_id
GROUP BY c.id, c.name ORDER BY average_price DESC, c.id;

-- Q12: 서브쿼리 - 전체 평균 가격보다 비싼 책을 찾는다.
SELECT title, price FROM book WHERE price > (SELECT AVG(price) FROM book)
ORDER BY price DESC, id;

-- Q13: UPDATE - 12번 대여의 반납일을 기록한다.
UPDATE rental SET returned_at = '2026-10-13' WHERE id = 12;

-- Q14: DELETE - 잘못 등록했다고 가정한 16번 대여 기록을 삭제한다.
DELETE FROM rental WHERE id = 16;

-- Q15: 인덱스 - 회원별 대여 조회와 member_id JOIN에 사용할 탐색 경로를 만든다.
CREATE INDEX idx_rental_member_id ON rental(member_id);

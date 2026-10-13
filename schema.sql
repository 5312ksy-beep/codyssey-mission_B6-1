-- SQLite용 도서 대여 DB. 실행 도구에서도 연결마다 FK 검사를 활성화한다.
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

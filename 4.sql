--SMAZANI TABULEK--
DROP TABLE student_studijni_program;
DROP TABLE  predmet_student;
DROP TABLE okruh_predmetu_predmet;
DROP TABLE doktorand_predmet;
DROP TABLE okruh_predmetu;
DROP TABLE obor;
DROP TABLE predmet;
DROP TABLE studijni_program;
DROP TABLE doktorand;
DROP TABLE student;
DROP MATERIALIZED VIEW LOG ON predmet;
DROP MATERIALIZED VIEW predmet_info;
DROP FUNCTION stripAccentsv;

--VYTVORENI TABULEK--
CREATE TABLE studijni_program (
    id_programu varchar(20) NOT NULL PRIMARY KEY,
    fakulta varchar(255) NOT NULL,
    delka int NOT NULL,
    forma_studia varchar(11) NOT NULL CHECK(forma_studia IN ('Prezenční','Dálkové'))
);

CREATE TABLE obor (
    id_oboru varchar(10) NOT NULL PRIMARY KEY,
    nazev_oboru varchar(255) NOT NULL,
    akreditace_do date NOT NULL ,
    id_programu varchar(20) NOT NULL, --má
    constraint studijni_program_obor_fk
                FOREIGN KEY (id_programu) REFERENCES studijni_program (id_programu)
                ON DELETE SET NULL
);

CREATE TABLE okruh_predmetu(
    id_okruhu varchar(3) NOT NULL CHECK(id_okruhu IN ('P','PVT','V')),
    semestr varchar(6) NOT NULL CHECK(semestr IN ('Zimní','Letní')),
    id_oboru varchar(10) NOT NULL,
    CONSTRAINT id_oboru_fk
        FOREIGN KEY (id_oboru) REFERENCES obor (id_oboru),
    CONSTRAINT okruh_predmetu_pk
        PRIMARY KEY (id_okruhu,semestr,id_oboru),
    min_kreditu int DEFAULT 0
);

CREATE TABLE predmet(
    id_predmetu varchar(3) NOT NULL PRIMARY KEY,
    nazev varchar(255) NOT NULL,
    kreditovy_obnos int NOT NULL,
    zpusob_zakonceni varchar(21) NOT NULL CHECK(zpusob_zakonceni IN ('Zápočet','Klasifikovaný zápočet','Zkouška')),
    zapocet varchar(5) NOT NULL CHECK (zapocet IN ('ANO','NE')),
    garant varchar(80)
);

CREATE TABLE okruh_predmetu_predmet ( --zahrnuje
    id_okruhu varchar(3) NOT NULL,
    semestr varchar(6) NOT NULL,
    id_predmetu varchar(3) NOT NULL,
    id_oboru varchar(20) NOT NULL,
    CONSTRAINT okruh_predmetu_predmet_pk
            PRIMARY KEY (id_okruhu,semestr,id_predmetu),
    CONSTRAINT okruh_predmetu_predmet_okruh_fk
            FOREIGN KEY (id_okruhu,semestr,id_oboru) REFERENCES okruh_predmetu (id_okruhu, semestr,id_oboru)
            ON DELETE CASCADE,
    CONSTRAINT okruh_predmetu_predmet_predmet_fk
            FOREIGN KEY (id_predmetu) REFERENCES predmet (id_predmetu)
            ON DELETE CASCADE
);

CREATE TABLE student(
    login varchar(8) NOT NULL PRIMARY KEY,
    jmeno varchar(80) NOT NULL,
    prijmeni varchar(80) NOT NULL,
    adresa_ulice varchar(80) NOT NULL,
    adresa_ulice_popisne int NOT NULL,
    adresa_mesto varchar(80) NOT NULL,
    adresa_psc int NOT NULL CHECK (REGEXP_LIKE(adresa_psc,'[0-9]{5}')),
    adresa_stat varchar(80) NOT NULL,
    datum_nar DATE NOT NULL,
    pohlavi varchar(5) NOT NULL CHECK ( pohlavi in ('Muž','Žena'))
);

CREATE TABLE doktorand(
    login varchar(8) NOT NULL,
    CONSTRAINT doktorand_fk
        FOREIGN KEY (login) REFERENCES student (login)
        ON DELETE CASCADE,
    CONSTRAINT doktorand_pk
        PRIMARY KEY (login),
    titul varchar(20)
);


CREATE TABLE predmet_student ( --registruje
    login varchar(8),
    id_predmetu varchar(3) NOT NULL,
    CONSTRAINT predmet_student_pk
            PRIMARY KEY (login,id_predmetu),
    CONSTRAINT predmet_student_predmet_fk
            FOREIGN KEY (id_predmetu) REFERENCES predmet (id_predmetu)
            ON DELETE CASCADE,
    CONSTRAINT predmet_student_student_fk
            FOREIGN KEY (login) REFERENCES student (login)
            ON DELETE CASCADE
);

CREATE TABLE student_studijni_program ( --studuje
    login varchar(8) NOT NULL,
    id_programu varchar(20) NOT NULL,
    CONSTRAINT student_studijni_program_pk
        PRIMARY KEY (login,id_programu),
    CONSTRAINT student_studijni_program_student_fk
        FOREIGN KEY (login) REFERENCES student (login)
        ON DELETE CASCADE,
    CONSTRAINT student_studijni_program_studijni_program_fk
        FOREIGN KEY (id_programu) REFERENCES studijni_program (id_programu)
        ON DELETE CASCADE
);

CREATE TABLE doktorand_predmet ( --podili se
    login varchar(8) NOT NULL,
    id_predmetu varchar(3) NOT NULL,
    CONSTRAINT doktorand_predmet_pk
        PRIMARY KEY (login,id_predmetu),
    CONSTRAINT doktorand_predmet_doktorand_fk
        FOREIGN KEY (login) REFERENCES doktorand (login)
        ON DELETE CASCADE,
     CONSTRAINT doktorand_predmet_predmet_fk
        FOREIGN KEY (id_predmetu) REFERENCES predmet (id_predmetu)
        ON DELETE CASCADE
);


--NAPLNENI TABULEK--

INSERT INTO  studijni_program (id_programu, fakulta, delka, forma_studia)
VALUES ('IT-BC-3','Fakulta Informačních technologií',3,'Prezenční');
INSERT INTO  studijni_program (id_programu, fakulta, delka, forma_studia)
VALUES ('IT-MGR-2','Fakulta Informačních technologií',2,'Prezenční');
INSERT INTO  studijni_program (id_programu, fakulta, delka, forma_studia)
VALUES ('MITAI','Fakulta Informačních technologií',2,'Prezenční');
INSERT INTO  studijni_program (id_programu, fakulta, delka, forma_studia)
VALUES ('VTI-DR-4','Fakulta Informačních technologií',4,'Prezenční');

--trigger pro kontrolu data akreditace, pokud je datum akreditace mensi nez dnesni datum vyvola se vyjimka
CREATE OR REPLACE TRIGGER akreditace_date_check
AFTER INSERT OR UPDATE ON obor
FOR EACH ROW
BEGIN
    IF :NEW.akreditace_do is null OR
    :NEW.akreditace_do < current_date
    THEN
        RAISE_APPLICATION_ERROR(-20343,'Agreditace oboru vypršela nebo je chybně zadaná');
    END IF;

END;

--pri vlozeni oboru s datem akreditace koncicim v roce 2018 vyvola se vyjimka
--INSERT INTO obor(id_oboru, nazev_oboru, akreditace_do, id_programu)
--VALUES ('TST','Testovací Obor',TO_DATE('2018', 'yyyy'),'TE-ST-3');
--################

INSERT INTO obor(id_oboru, nazev_oboru, akreditace_do, id_programu)
VALUES ('BIT','Informační technologie',TO_DATE('2025', 'yyyy'),'IT-BC-3');
INSERT INTO obor(id_oboru, nazev_oboru, akreditace_do, id_programu)
VALUES ('NBIO','Bioinformatika a biocomputing',TO_DATE('2029', 'yyyy'),'MITAI');
INSERT INTO obor(id_oboru, nazev_oboru, akreditace_do, id_programu)
VALUES ('DVI4','Výpočetní technika a informatika',TO_DATE('2024', 'yyyy'),'VTI-DR-4');

INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('PVT','Letní','BIT',5);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('P','Letní','BIT',15);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('V','Letní','BIT',0);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('PVT','Zimní','BIT',5);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('P','Zimní','BIT',15);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('V','Zimní','BIT',0);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('P','Zimní','NBIO',15);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('V','Zimní','NBIO',0);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('P','Letní','NBIO',15);
INSERT INTO okruh_predmetu(id_okruhu, semestr, id_oboru, min_kreditu)
VALUES ('V','Letní','NBIO',0);

INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('TST','TestPredmet',5,'Zkouška','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('IAL','Algoritmy',5,'Zkouška','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('ISS','Signály a systémy',6,'Zkouška','NE',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('HVR','Manažerské vedení lidí',3,'Zápočet','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('IJA','Seminář Java',4,'Zápočet','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('ITW','Tvorba webových stránek',5,'Zápočet','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('IZU','Základy uměnlé inteligence',4,'Zkouška','ANO',NULL);
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('AVS','Architektury výpočetních systémů',5,'Zkouška','ANO','doc. Ing. Jiří Jaroš, Ph.D.');
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('BIF','	Bioinformatika',5,'Zkouška','NE','Ing. Tomáš Martínek, Ph.D.');
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('PBI','Pokročilá bioinformatika',4,'Zkouška','NE','Ing. Matej Lexa, Ph.D.');
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('IW1','Desktop systémy Microsoft Windows',5,'Zkouška','ANO','Ing. Igor Hnízdo, Ph.D.');
INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('IPZ','Periferní zařízení',3,'Zkouška','NE','Ing. Ivo Perifer, Ph.D.');

--okruhy predmetu
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Zimní','IAL','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Zimní','ISS','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('V','Zimní','HVR','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('PVT','Letní','IJA','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('V','Letní','ITW','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Letní','IZU','BIT');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Zimní','AVS','NBIO');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Zimní','BIF','NBIO');
INSERT INTO okruh_predmetu_predmet(id_okruhu, semestr, id_predmetu, id_oboru)
VALUES ('P','Zimní','PBI','NBIO');

--pomocna funkce maze diakritiku v prijmeni pro generaci loginu
CREATE OR REPLACE FUNCTION stripAccentsv(prijmeni in varchar) RETURN varchar
AS
returnPrijemni varchar(20);
BEGIN
    returnPrijemni := lower(prijmeni);
    returnPrijemni := replace(returnPrijemni,'ě','e');
    returnPrijemni := replace(returnPrijemni,'š','s');
    returnPrijemni := replace(returnPrijemni,'č','c');
    returnPrijemni := replace(returnPrijemni,'ř','r');
    returnPrijemni := replace(returnPrijemni,'ž','z');
    returnPrijemni := replace(returnPrijemni,'ý','y');
    returnPrijemni := replace(returnPrijemni,'á','a');
    returnPrijemni := replace(returnPrijemni,'í','i');
    returnPrijemni := replace(returnPrijemni,'é','e');
    returnPrijemni := replace(returnPrijemni,'ů','u');
    returnPrijemni := replace(returnPrijemni,'ú','u');
    return returnPrijemni;
end;

--trigger generujici student login pomoci 5ti ci mene pismen prijmeni
CREATE OR REPLACE TRIGGER login_trigger
	BEFORE INSERT ON student
	FOR EACH ROW
    declare new_login varchar(20);
BEGIN
	IF :NEW.login IS NULL THEN
	    new_login := stripAccentsv(:NEW.prijmeni);
	    if LENGTH(:NEW.prijmeni) < 5 THEN
	        :NEW.login := to_char(concat(concat('x',substr(new_login,0,length(:NEW.prijmeni))),'00'));
            --:NEW.login := to_char(concat(concat('x',lower(substr(:NEW.prijmeni,0,length(:NEW.prijmeni)))),'00'));
            end if;
	    if LENGTH(:NEW.prijmeni) >= 5 THEN
	        :NEW.login := to_char(concat(concat('x',substr(new_login,0,5)),'00'));
            --:NEW.login := to_char(concat(concat('x',lower(substr(:NEW.prijmeni,0,5))),'00'));
        end if;
	END IF;
END;

--studenti
INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Jan','Hranický','Josefa Kotase',33,'Ostrava',70030,'České republika',TO_DATE('1999-02-21', 'yyyy/mm/dd'),'Muž');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Jonáš','Svoboda','Na Rybníčku',8,'Opava',74601,'České republika',TO_DATE('1999-08-08', 'yyyy/mm/dd'),'Muž');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xsvobo00','IT-BC-3');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xsvobo00','IAL');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xsvobo00','ISS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xsvobo00','HVR');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xsvobo00','IJA');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xsvobo00','IZU');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Radek','Radkovič','Palackého náměstí',42,'Praha',19000,'České republika',TO_DATE('1999-01-18', 'yyyy/mm/dd'),'Muž');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xradko00','IT-BC-3');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xradko00','IAL');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xradko00','ISS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xradko00','HVR');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xradko00','IJA');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xradko00','ITW');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Xénie','Uhrančivá','Dolní náměstí',18,'Opava',74601,'České republika',TO_DATE('1999-05-05', 'yyyy/mm/dd'),'Žena');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xuhran00','IT-BC-3');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xuhran00','IAL');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xuhran00','ISS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xuhran00','IZU');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Greta','Štrůdlová','Frýdko-místecká ulice',10,'Frýdek Místek',74800,'České republika',TO_DATE('1998-12-24', 'yyyy/mm/dd'),'Žena');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xstrud00','IT-BC-3');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xstrud00','IAL');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xstrud00','ISS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xstrud00','IZU');

--doktorandi

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Tereza','Nezvěstná','Božetěchova',42,'Brno',61200,'České republika',TO_DATE('1992-12-12', 'yyyy/mm/dd'),'Žena');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xnezve00','MITAI');
INSERT INTO doktorand(login, titul)
VALUES ('xnezve00','ing.');
INSERT INTO doktorand_predmet(login, id_predmetu)
VALUES ('xnezve00','ISS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xnezve00','BIF');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xnezve00','AVS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xnezve00','PBI');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Josef','Hon','Božetěchova',42,'Brno',61200,'České republika',TO_DATE('1992-05-07', 'yyyy/mm/dd'),'Muž');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xhon00','MITAI');
INSERT INTO doktorand(login, titul)
VALUES ('xhon00','ing.');
INSERT INTO doktorand_predmet(login, id_predmetu)
VALUES ('xhon00','ITW');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xhon00','AVS');
INSERT INTO predmet_student(login, id_predmetu)
VALUES ('xhon00','PBI');

INSERT INTO student(jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('Filip','Martiček','Božetěchova',42,'Brno',61200,'České republika',TO_DATE('1993-01-01', 'yyyy/mm/dd'),'Muž');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xmarti00','MITAI');
INSERT INTO doktorand(login, titul)
VALUES ('xmarti00','ing.');
INSERT INTO doktorand_predmet(login, id_predmetu)
VALUES ('xmarti00','IZU');

INSERT INTO student(login, jmeno, prijmeni, adresa_ulice, adresa_ulice_popisne, adresa_mesto, adresa_psc, adresa_stat, datum_nar, pohlavi)
VALUES('xrando00','Random','Mák','Random Ulice',33,'Ostrava',70030,'České republika',TO_DATE('1992-02-21', 'yyyy/mm/dd'),'Muž');
INSERT INTO student_studijni_program(login, id_programu)
VALUES ('xrando00','MITAI');
INSERT INTO doktorand(login, titul)
VALUES ('xrando00','ing.');
INSERT INTO doktorand_predmet(login, id_predmetu)
VALUES ('xrando00','ISS');
--=================================================================================
--3. ČÁST SELECT
--
--1/2 Join 2 tabulek. Které obory nabízí magisterský studijní program ?
SELECT obor.id_oboru as "Id oboru",
       obor.nazev_oboru as "Název oboru"
from obor JOIN studijni_program sp on sp.id_programu = obor.id_programu
WHERE sp.delka = '2';
--2/2 Join 2 tabulek. Kteří studenti jsou doktorandi ?
SELECT student.login as "Login",
       student.jmeno as "Jméno",
       student.prijmeni as "Příjmení"
FROM student JOIN doktorand on student.login = doktorand.login;

--Join 3 tabulek. Výpis doktorandu, kterí pomáhaji s jinými předměty.
SELECT doktorand.login as "Login",
       student.jmeno as "Jméno",
       student.prijmeni as "Příjmení",
       doktorand_predmet.id_predmetu as "Id předmětu"
from doktorand
JOIN student on student.login = doktorand.login
JOIN doktorand_predmet on doktorand.login = doktorand_predmet.login;

--1/1 dotaz s predikatem IN. Ktere předmety si nikdo nezaregistroval ?
SELECT predmet.id_predmetu as "Id předmětu",
       predmet.nazev as "Název předmětu"
FROM predmet
WHERE predmet.id_predmetu NOT IN (
    SELECT ps.id_predmetu
    FROM predmet_student ps
    );

--1/1 dotaz s predikátem EXISTS. Výpis studentů žijících v Brně.
SELECT student.login as "Login",
       student.jmeno as "Jméno",
       student.prijmeni as "Příjmení"
FROM student
WHERE EXISTS (SELECT adresa_mesto FROM student WHERE adresa_mesto = 'Brno');

--1/2 GROUP BY s agregační fcí COUNT. Počet studentů v rámci jednotlivých programů.
SELECT student_studijni_program.id_programu as "Id programu",
       COUNT(student_studijni_program.login) as "Počet studentů"
FROM student_studijni_program
GROUP BY student_studijni_program.id_programu
ORDER BY COUNT(student_studijni_program.login) DESC;

--2/2 GROUP BY s agreg. fcí COUNT. Procentuální zastoupení pohlaví v seznamu studentů.
SELECT student.pohlavi as "Pohlaví",
       COUNT(*) / CAST( SUM(count(*)) over () as float) as "Zastoupení"
FROM student
GROUP BY student.pohlavi;

--1/1 spojeni tří tabulek. Výpis počtu kreditů, které mají zaregistrováni jednotliví studenti
SELECT student.login as "Login",
       sum(p.kreditovy_obnos) as "Počet Kreditů"
From student
Join predmet_student ps ON student.login = ps.login
Join predmet p ON p.id_predmetu = ps.id_predmetu
GROUP BY student.login
ORDER BY sum(p.kreditovy_obnos) DESC;

--#########################################################################
-- 4. cast

--triggery 2x z toho jeden generujici PK nejake tabulky
--demonstrace prvniho triggeru vsichni studenti a doktorandi by meli mit login ve tvaru "x - za 5 pismen sveho prijmeni - 00"
select student.login from student;

--procedury

--Procedura 1# počítá procentuální zastoupení pohlaví v studentských řadách
CREATE OR REPLACE PROCEDURE studenti_pohlavi
AS
	zeny NUMBER;
	muzi NUMBER;
    total NUMBER;

BEGIN
	SELECT COUNT(*) INTO "zeny" FROM "studet"
    WHERE pohlavi = "Žena";
    SELECT COUNT(*) INTO "muzi" FROM "student"
    WHERE pohlavi = "Muž";
    total := muzi + zeny;
    muzi := muzi / total * 100;
    zeny := zeny / total * 100;

    dbms_output.put_line('Procentuální zastoupení pohlaví mezi studenty:');¨
    dbms_output.put_line('Muži:'muzi'%.')
    dbms_output.put_line('Ženy:'zeny'%.')
END;

--Procedura 2# spočítá počet studentů jednotlivých programů (bakalářské studium, magisterské studium ...)
CREATE PROCEDURE "seznam_studentu_programu"
    ("program_student" IN VARCHAR)
BEGIN
SELECT * FROM student_studijni_program WHERE id_programu = "program_student";
END;
--Příklad použití 
BEGIN student_studijni_program('MITAI'); END;

--Procedura 3# 
--TODO

--index pro optimalizaci + ukazka + EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT student.adresa_mesto,
       count(student.login)
from student
JOIN student_studijni_program ON student.login = student_studijni_program.login
JOIN studijni_program on student_studijni_program.id_programu = studijni_program.id_programu
WHERE studijni_program.delka = 3
GROUP BY student.adresa_mesto
ORDER BY count(student.login) DESC;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

CREATE INDEX student_mesto_index on student (adresa_mesto,login);
CREATE INDEX studijni_program_index on studijni_program (delka,id_programu);

EXPLAIN PLAN FOR
SELECT student.adresa_mesto,
       count(student.login)
from student
JOIN student_studijni_program ON student.login = student_studijni_program.login
JOIN studijni_program on student_studijni_program.id_programu = studijni_program.id_programu
WHERE studijni_program.delka = 3
GROUP BY student.adresa_mesto
ORDER BY count(student.login) DESC;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

DROP INDEX student_mesto_index;
DROP INDEX studijni_program_index;

-- definice pristupovych prav
--xsvobod1t
GRANT ALL ON doktorand TO xsvobo1t;
GRANT ALL ON obor TO xsvobo1t;
GRANT ALL ON okruh_predmetu TO xsvobo1t;
GRANT ALL ON predmet TO xsvobo1t;
GRANT ALL ON student TO xsvobo1t;
GRANT ALL ON studijni_program TO xsvobo1t;
--plus procedury

--materilalizovany pohled

CREATE MATERIALIZED VIEW LOG ON predmet WITH PRIMARY KEY, ROWID(kreditovy_obnos) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW predmet_info
CACHE
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
ENABLE QUERY REWRITE
AS SELECT p.kreditovy_obnos, count(p.kreditovy_obnos) as kredity
FROM predmet p
GROUP BY p.kreditovy_obnos
ORDER BY count(p.kreditovy_obnos) desc;

GRANT ALL ON predmet_info TO xsvobo1t;

SELECT * from predmet_info;

INSERT INTO predmet(id_predmetu, nazev, kreditovy_obnos, zpusob_zakonceni, zapocet, garant)
VALUES ('TSs','TesttPredmet',6,'Zkouška','ANO',NULL);

COMMIT;

SELECT * from predmet_info;

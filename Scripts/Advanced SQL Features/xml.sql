/**
--test tables for xml examples:
create table t1 (id  int IDENTITY, name varchar(10), expn money, date date,
constraint pk_t1 primary key clustered (id) ,
index ix_t1 nonclustered (expn) )
GO
insert into t1 (name, expn, date) values ('M',50000,'12/31/13'),('M',40000,'12/31/14'),('M',60000,'12/31/15'),('T',20000,'12/31/13'),('T',50000,'12/31/14'),('T',40000,'12/31/15')
 
create table t2 (id  int IDENTITY, city varchar(10), store varchar(20), date datetime DEFAULT getdate(),
constraint pk_t2 primary key clustered (id) ,
index ix_t1 nonclustered (store) )
Go
INSERT INTO t2 (city,store) VALUES ('Fresno','Big5'),('Fresno','Costco'),('Clovis','Vons'),('Selma','Chevron'),('Sanger','7 Eleven'),('Clovis','SaveMart');
 
drop table t2
drop table t1
 
ALTER TABLE t1 ADD Constraint uq_t1
 
*/
 
select * from t1 inner join t2 on t1.id=t2.id
 
--**the nesting depends on the order the columns are placed in the SELECT statement and all columns will be attributes unless ELEMENTS is specified **
--RAW:  <row> will be the provided element name
select store, name, expn FROM t1 inner join t2 on t1.id=t2.id FOR XML RAW
select store, name, expn FROM t1 inner join t2 on t1.id=t2.id FOR XML RAW,ELEMENTS
 
--AUTO:  the table name will be the provided element name:
select store, name, expn FROM t1 inner join t2 on t1.id=t2.id FOR XML AUTO, ELEMENTS
select name, store,expn FROM t1 inner join t2 on t1.id=t2.id FOR XML AUTO
 
--PATH:  more control, we can specify the order of the elements, columns named with @ are attributes and the rest are elements
select name AS [@Name], expn AS [@expn], date FROM t1 FOR XML PATH ('Table1'),ROOT('Table2')
 
 
 
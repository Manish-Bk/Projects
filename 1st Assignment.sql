-- use your database--
use jooins;

-- bank1 table creation --
create table bank1(Account_No int primary key auto_increment, Acc_Name varchar(30) not null, Balance numeric(10,2));

-- bank_update1 table creation --
create table bank_udpate1 (Account_No int not null ,
Acc_Name varchar(30) not null,
changed_id timestamp,
before_Bal numeric(10,2) not null,
after_Bal numeric(10,2) not null,
Actions varchar(10) null,
Transaction_amt int null);

-- inserting the value inot bank1 table --
insert into bank1(Acc_Name, Balance ) values('Mani',10000.00);

-- trigger for after_bank_update1 (debit) update on bank1 --
delimiter $$
create trigger after_bank_update1 after update on bank1 for each row
begin
if(new.Balance<old.Balance) then
	insert into bank_udpate1(Account_No , Acc_Name , changed_id , before_Bal , after_Bal, Actions, Transaction_amt ) 
	values(old.Account_No, old.Acc_Name, now(), old.Balance , new.Balance, 'Debit',-(old.Balance-new.Balance));
end IF;
end $$

-- trigger for after_bank_update2 (credit) update on bank1 --
delimiter $$
create trigger after_bank_update2 after update on bank1 for each row
begin
if(new.Balance>old.Balance) then
	insert into bank_udpate1(Account_No , Acc_Name , changed_id , before_Bal , after_Bal, Actions ,Transaction_amt) 
	values(old.Account_No, old.Acc_Name, now(), old.Balance , new.Balance, 'Credit',+(new.Balance-old.Balance));
end IF;
end $$

-- update statemnt bank1 table --
update bank1 set Balance = (Balance-5000) where Account_No = 1;
update bank1 set Balance = (Balance+10000) where Account_No = 1;

-- dropping the both the triggers --
drop trigger after_bank_update1;
drop trigger after_bank_update2;


-- CREATE PROCEDURE HOURLY_SUM -- 
DELIMITER //
CREATE PROCEDURE HOURLY_SUM (IN Account_No INT, OUT WTotal numeric(10,2), OUT DTotal numeric(10,2))
BEGIN
    SELECT sum(Transaction_amt) INTO WTotal FROM jooins.bank_udpate1
	WHERE Actions = 'Debit' AND Account_No=Account_No AND changed_id >= Date_sub(now(),interval 1 hour);
    
    SELECT sum(Transaction_amt) INTO DTotal FROM jooins.bank_udpate1
	WHERE Actions = 'Credit' AND Account_No=Account_No AND changed_id >= Date_sub(now(),interval 1 hour);
END //

-- DROP THE PROCEDURE --
DROP PROCEDURE HOURLY_SUM;

-- CALLING THE PROCEDURE --
CALL HOURLY_SUM(1, @WTotal, @DTotal);

-- DISPLAYING THE CALLED PROCEDURE --
SELECT @WTotal, @DTotal;

-- CREAETING EVENT TO CALL PROCEDURE HOURLY--
CREATE EVENT MyEvent
    ON SCHEDULE EVERY 1 HOUR
    DO
      CALL HOURLY_SUM(1, @WTotal, @DTotal);

-- DROP THR EVENT --
DROP EVENT MyEvent;
      


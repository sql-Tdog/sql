--Encrypt by passphrase example--------------------------------------------------
ALTER TABLE Customers ADD CardNumber_EncryptedbyPassphrase varbinary(256);   
GO  

DECLARE @PassphraseEnteredByUser nvarchar(128);  
SET @PassphraseEnteredByUser = 'A little learning is a dangerous thing!';  

-- Update the record for the user's credit card.  
UPDATE Customers SET CardNumber_EncryptedbyPassphrase = EncryptByPassPhrase(@PassphraseEnteredByUser, CC, 1, CONVERT( varbinary, CC))  
GO  

select * from Customers;


-- Digitally Sign Data example -------------------------------------------------
CREATE TABLE [SignedData04](Description nvarchar(max), Data nvarchar(max), DataSignature varbinary(8000));  
GO  
-- Store data together with its signature  
DECLARE @clear_text_data nvarchar(max);  
set @clear_text_data = N'Important numbers 2, 3, 5, 7, 11, 13, 17,   
      19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79,  
      83, 89, 97';  
INSERT INTO [SignedData04]   
    VALUES( N'data encrypted by asymmetric key ''PrimeKey''',  
    @clear_text_data, SignByAsymKey( AsymKey_Id( 'PrimeKey' ),  
    @clear_text_data, N'pGFD4bb925DGvbd2439587y' ));  
GO  

SELECT * FROM SignedData04
--to create a view that is persisted to disk (an indexed view), use the SCHEMABINDING option


ALTER VIEW DimClaim WITH SCHEMABINDING 
AS
SELECT        DCB.Bill_Basis, DCB.Billed_Price_List, FC.Claim_ID, FC.claim_key, CONVERT(DATE, CAST(FC.date_entered_key AS VARCHAR(8)), 112) AS Date_Entered, 
                         CONVERT(DATETIME, CAST(FC.date_filled_key AS VARCHAR(8)), 112) AS Date_Filled, CONVERT(DATE, CAST(FC.date_period_end_key AS VARCHAR(8)), 112) 
                         AS Date_Period_End, FC.Date_Time_Entered, CONVERT(DATETIME, CAST(FC.date_written_key AS VARCHAR(8)), 112) AS Date_Written, DCC.DAW_Allowed_CD, 
                         DCD.Drug_Type, DGL.GL_Company_ID, DGL.GL_Dept_ID, DCI.Is_Accounting, DCI.Is_Compound, DCI.Is_Formulary, DCI.Is_Maintenance, DCI.Is_Specialty, 
                         DMA.Member_Age, DMD.Member_Dept_ID, DCD.Multi_Source_CD, DCR.New_Refill, DCR.Number_Refills_Auth, DCC.Payee_Type, FC.Prescription_Number, 
                         DCB.Reimburse_Basis, DCB.Reimbursed_Price_List, FC.Reversal_Claim_ID, DCC.Service_Type, DCC.Transaction_Type, DCC.Bill_Sequence, 
                         DCI.Is_Emergency_Fill, DCC.Prescription_Origin, DCC.Other_Coverage, DCI.PHS_340B_Indicator, DCI.CNC_Specialty, DCI.Is_Late_Payment, DCC.TPL_Override, 
                         FC.Claim_Cost_AR_Invoice_Number, FC.Claim_Fee_AR_Invoice_Number, FC.Claim_Rebate_AR_Invoice_Number, FC.Claim_AP_Invoice_Number, 
                         DCC.Pharmacy_Service_Type, DCC.Patient_Residence, DCC.Processor_Control_Number
FROM            dbo.FctClaims AS FC INNER JOIN
                         dbo.DimClaimBasis AS DCB ON FC.claim_basis_key = DCB.claim_basis_key INNER JOIN
                         dbo.DimClaimCode AS DCC ON FC.claim_code_key = DCC.claim_code_key INNER JOIN
                         dbo.DimClaimIndicator AS DCI ON FC.claim_ind_key = DCI.claim_ind_key INNER JOIN
                         dbo.DimClaimRefill AS DCR ON FC.claim_refill_key = DCR.claim_refill_key INNER JOIN
                         dbo.DimGL AS DGL ON FC.gl_key = DGL.gl_key INNER JOIN
                         dbo.DimMemberAge AS DMA ON FC.mbrage_key = DMA.mbrage_key INNER JOIN
                         dbo.DimMemberDept AS DMD ON FC.mbrdept_key = DMD.mbrdept_key INNER JOIN
                         dbo.DimClaimDrug AS DCD ON FC.claim_drug_key = DCD.claim_drug_key


--create index on the view
CREATE CLUSTERED  INDEX pk_DimClaim ON dbo.DimClaim ([claim_key]) WITH (DATA_COMPRESSION=PAGE) ON DimClaimClustered --00:32:35 on T

CREATE NONCLUSTERED INDEX ix_DimClaim ON dbo.DimClaim ([Bill_Basis],[Billed_Price_List],[Claim_ID],[Date_Entered],[Date_Filled]	,[Date_Period_End]
	,[Date_Time_Entered],[Date_Written],[DAW_Allowed_CD],[Drug_Type],[GL_Company_ID],[GL_Dept_ID],[Is_Accounting],[Is_Compound],[Is_Formulary]) INCLUDE ([Is_Maintenance]
	,[Is_Specialty],[Member_Age],[Member_Dept_ID],[Multi_Source_CD],[New_Refill],[Number_Refills_Auth],[Payee_Type],[Prescription_Number],[Reimburse_Basis]
	,[Reimbursed_Price_List],[Reversal_Claim_ID],[Service_Type],[Transaction_Type],[Bill_Sequence],[Is_Emergency_Fill],[Prescription_Origin],[Other_Coverage]
	,[PHS_340B_Indicator],[CNC_Specialty],[Is_Late_Payment],[TPL_Override],[Claim_Cost_AR_Invoice_Number],[Claim_Fee_AR_Invoice_Number]
	,[Claim_Rebate_AR_Invoice_Number],[Claim_AP_Invoice_Number],[Pharmacy_Service_Type]   ,[Patient_Residence]   ,[Processor_Control_Number]	)
	WITH (DATA_COMPRESSION=PAGE) ON DimClaimNonclustered;  --00:42:20


DROP INDEX pk_DimClaim ON dbo.DimClaim

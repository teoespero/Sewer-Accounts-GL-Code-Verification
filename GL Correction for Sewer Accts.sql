--------------------------------------------------------------------------
-- Sewer Accounts GL Code Verification
-- Written by: Teo Espero, IT Administrator
-- Date written: 01/19/2023
-- Description:
--		This code was written to audit Service Rate GL Codes for Sewer
-- 
-- Code Revision History:
-- 
-- 	base code (01/19)
--
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- step #1
-- get all the active accounts in springbrook
--------------------------------------------------------------------------

select 
	replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar) as AccountNum,
	lot_no
	into #activeAccounts
from ub_master mast
where
	acct_status='active'

-- select * from #activeAccounts

--------------------------------------------------------------------------
-- step #2
-- limit the data set to only include accounts that has a Sewer service 
-- rate. Note that additional requirements include:
--			- Not inactivated
--			- connect date not equal to final date
--------------------------------------------------------------------------

select 
	replicate('0', 6 - len(usr.cust_no)) + cast (usr.cust_no as varchar)+ '-'+replicate('0', 3 - len(usr.cust_sequence)) + cast (usr.cust_sequence as varchar) as AcctNum,
	aca.lot_no,
	usr.rate_connect_date,
	usr.rate_final_date,
	usr.service_code
	into #getSewerAccts
from ub_service_rate usr
inner join
	#activeAccounts aca
	on aca.AccountNum=replicate('0', 6 - len(usr.cust_no)) + cast (usr.cust_no as varchar)+ '-'+replicate('0', 3 - len(usr.cust_sequence)) + cast (usr.cust_sequence as varchar)
where
	service_number=2
	and service_code in (
		select 
			distinct
			service_code
		from ub_service 
		where
			service_number = 2
			and (service_code not like 'SC%' and service_code not like 'SX%')
			and len(service_code) > 2
	)
	and (rate_final_date is null)
order by
	replicate('0', 6 - len(usr.cust_no)) + cast (usr.cust_no as varchar)+ '-'+replicate('0', 3 - len(usr.cust_sequence)) + cast (usr.cust_sequence as varchar)

-- select * from #getSewerAccts

--------------------------------------------------------------------------
-- step #3
-- limit the data set to only include accounts that has a Sewer service 
-- rate. Note that additional requirements include:
--			- Not inactivated
--			- connect date not equal to final date
--------------------------------------------------------------------------


select 
	l.misc_2 as STCategory,
	l.misc_1 as Boundary,
	l.misc_5 as Subdivision,
	gsa.AcctNum,
	gsa.lot_no,
	gsa.service_code,
	srv.rev_acct_1,
	srv.rev_acct_2,
	srv.rev_acct_3,
	srv.rev_acct_4,
	gl.[description]
from #getSewerAccts gsa
inner join
	ub_service srv
	on srv.service_code=gsa.service_code
inner join
	lot l
	on l.lot_no=gsa.lot_no
left join
	gl_chart gl
	on gl.acct_1=srv.rev_acct_1
	and gl.acct_2=srv.rev_acct_2
	and gl.acct_3=srv.rev_acct_3
	and gl.acct_4=srv.rev_acct_4
	and gl.fiscal_year=2023
order by
	l.misc_1,
	l.misc_2

--------------------------------------------------------------------------
-- step #5
-- cleanup
--------------------------------------------------------------------------

drop table #activeAccounts
drop table #getSewerAccts

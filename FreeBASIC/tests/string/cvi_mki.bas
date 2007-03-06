# include "fbcu.bi"




namespace fbc_tests.string_.cvi_mki

	const as double  cv_d  = cvd      ("TESTTEST")
	const as single  cv_s  = cvs      ("TESTTEST")
	const as integer cv_i  = cvi      ("TESTTEST")
	const as long    cv_l  = cvl      ("TESTTEST")
	const as short   cv_sh = cvshort  ("TESTTEST")
	const as longint cv_li = cvlongint("TESTTEST")
	
	sub CVXtest cdecl ()
		CU_ASSERT( cv_d  = cvd      ("TESTTEST") )
		CU_ASSERT( cv_s  = cvs      ("TESTTEST") )
		CU_ASSERT( cv_i  = cvi      ("TESTTEST") )
		CU_ASSERT( cv_l  = cvl      ("TESTTEST") )
		CU_ASSERT( cv_sh = cvshort  ("TESTTEST") )
		CU_ASSERT( cv_li = cvlongint("TESTTEST") )
	end sub
	
	const as double  m_d  = 10000
	const as integer m_i  = 10000
	const as long    m_l  = 10000
	const as longint m_li = 10000
	
	sub MKXtest cdecl ()
	
		dim as string mkd_d, mkd_i, mkd_l, mkd_li
		dim as string mks_d, mks_i, mks_l, mks_li
		dim as string mki_d, mki_i, mki_l, mki_li
		dim as string mkl_d, mkl_i, mkl_l, mkl_li
		dim as string mkshort_d, mkshort_i, mkshort_l, mkshort_li
		dim as string mklongint_d, mklongint_i, mklongint_l, mklongint_li
		
		#macro doMKX(token)
			token##_d  = token(m_d)
			token##_i  = token(m_i)
			token##_l  = token(m_l)
			token##_li = token(m_li)
		#endmacro
		
		doMKX(mkd)
		doMKX(mks)
		doMKX(mki)
		doMKX(mkl)
		doMKX(mkshort)
		doMKX(mklongint)
		
		#macro testMKX(token)
			CU_ASSERT( token##_d  = token( 10000.0              ) )
			CU_ASSERT( token##_i  = token( 10000                ) )
			CU_ASSERT( token##_l  = token( cast(long, 10000)    ) )
			CU_ASSERT( token##_li = token( cast(longint, 10000) ) )
		#endmacro
		
		testMKX(mkd)
		testMKX(mks)
		testMKX(mki)
		testMKX(mkl)
		testMKX(mkshort)
		testMKX(mklongint)
		
	end sub	

	sub ctor () constructor
	
		fbcu.add_suite("fbc_tests.string_.cv_mki")
		fbcu.add_test("cvi", @CVXtest)
		fbcu.add_test("mki", @MKXtest)
	
	end sub

end namespace
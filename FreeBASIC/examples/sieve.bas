''
'' ordinary sieve test
''

const INTERATIONS = 1000

  Dim Flags(0 to 8190) as integer
  dim iter as integer
  dim count as integer
  dim prime as integer
  dim k as integer
  dim i as integer
  dim x as double
  
  x = timer
  
  For Iter = 1 To INTERATIONS
    Count = 0 
    
    For I = 0 To 8190 
      Flags(I) = 1 
    Next  
    
    For I = 0 To 8190 
      If Flags(I)=1 Then 
        Prime = (I shl 1) + 3 
        K = I + Prime 
        While K <= 8190 
          Flags(K) = 0 
          K = K + Prime 
        Wend 
        Count = Count + 1 
      End If 
    Next  
  Next
  
  x = timer - x
  
  print "msecs taken:"; x
  print "count:"; count
  sleep
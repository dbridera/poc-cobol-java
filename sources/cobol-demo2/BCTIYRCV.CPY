      *--------------------------------------------------------------*          
      *REGISTRO DE COMUNICACIONS PARA GENERAR EL CODIGO DE CUENTA    *          
      *INTERBANCARIA PARA IMPACS O SAVINGS Y GENERAR LA CUENTA       *          
      *IMPACS O SAVINGS TENIENDO EL CODIGO INTERBANCARIO             *          
      *PREFIJO USADO : TI-YRCV-                                      *          
      *LONGITUD : 200                                                *          
      *--------------------------------------------------------------*          
       01  TI-YRCV-PARAMETROS.                                                  
           05  TI-YRCV-COD-INTFZ           PIC X(04).                           
           05  TI-YRCV-IND-CONV            PIC X(01).                           
               88  TI-YRCV-88-CCI-BCP      VALUE '1'.                           
               88  TI-YRCV-88-BCP-CCI      VALUE '2'.                           
           05  TI-YRCV-BSC-COD-FAM         PIC X(03).                           
               88  TI-YRCV-BSC-COD-FAM-IM  VALUE '004' '007'.                   
               88  TI-YRCV-BSC-COD-FAM-ST  VALUE '005' '009'.                   
           05  TI-YRCV-BSC-COD-PRO         PIC X(03).                           
           05  TI-YRCV-BSC-COD-SPR         PIC X(03).                           
           05  TI-YRCV-COD-CTA-CCI.                                             
               10  TI-YRCV-COD-BCO         PIC X(03).                           
               10  TI-YRCV-COD-OFI         PIC X(03).                           
               10  TI-YRCV-IDT-CTA         PIC X(01).                           
               10  TI-YRCV-NRO-CTA         PIC X(08).                           
               10  TI-YRCV-COD-MON         PIC X(01).                           
               10  TI-YRCV-DIG-INT1        PIC X(02).                           
               10  TI-YRCV-DIG-INT2        PIC X(02).                           
      *                                                                         
           05  TI-YRCV-COD-RETURN          PIC X(02).                           
           05  TI-YRCV-MSG-RETURN          PIC X(80).                           
           05  TI-YRCV-BSC-COD-FAM-RET     PIC X(03).                           
           05  TI-YRCV-BCP-EDIT-IM.                                             
               10  FILLER                  PIC X(07).                           
               10  TI-YRCV-OFI-BCP-IM      PIC X(03).                           
               10  TI-YRCV-NUM-BCP-IM      PIC X(07).                           
               10  TI-YRCV-MON-BCP-IM      PIC X(01).                           
               10  TI-YRCV-DIG-BCP-IM      PIC X(02).                           
           05  TI-YRCV-BCP-EDIT-ST REDEFINES TI-YRCV-BCP-EDIT-IM.               
               10  FILLER                  PIC X(06).                           
               10  TI-YRCV-OFI-BCP-ST      PIC X(03).                           
               10  TI-YRCV-NUM-BCP-ST      PIC X(08).                           
               10  TI-YRCV-MON-BCP-ST      PIC X(01).                           
               10  TI-YRCV-DIG-BCP-ST      PIC X(02).                           
           05  TI-YRCV-CUENTA-ITE-EDIT.                                         
               10  TI-YRCV-OFIBAN-ITE.                                          
                   15  TI-YRCV-BCO-ITE     PIC X(03).                           
                   15  TI-YRCV-OFI-ITE     PIC X(03).                           
               10  TI-YRCV-NUMERO-ITE.                                          
                   15  TI-YRCV-PRO-ITE     PIC X(01).                           
                   15  TI-YRCV-NUM-ITE     PIC X(08).                           
                   15  TI-YRCV-MON-ITE     PIC X(01).                           
                   15  TI-YRCV-DIG-INT     PIC X(02).                           
               10  TI-YRCV-DIG-CHEQUEO.                                         
                   15  TI-YRCV-DIG-ITE1    PIC X(01).                           
                   15  TI-YRCV-DIG-ITE2    PIC X(01).                           
           05  FILLER                      PIC X(41).                           

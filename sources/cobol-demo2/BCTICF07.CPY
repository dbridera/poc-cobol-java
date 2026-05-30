      ******************************************************************        
      * COPY        : BCTICF07                                         *        
      * APLICACION  : MODULO TTIB EN LINEA                             *        
      * DESCRIPCION : REGISTRO DE FILE PARA LOG DE EVENTOS             *        
      * ORGANIZACION: KSDS - LONGITUD DE LA LLAVE 41 BYTES             *        
      * L.R.        : 2400 BYTES (ANTES 1900)                          *        
      ******************************************************************        
       01  TI-CF07-REG-TRANS.                                                   
           05  TI-CF07-REG-KEY-TRANS.                                           
               10  TI-CF07-COD-PROCESO             PIC  X(03).                  
                   88  TI-CF07-88-COD-PROCESO-CON  VALUE 'CON'.                 
                   88  TI-CF07-88-COD-PROCESO-TRN  VALUE 'TRN'.                 
               10  TI-CF07-TIPO-ROL                PIC  X(01).                  
                   88  TI-CF07-88-TIPO-ROL-EMISOR  VALUE 'E'.                   
                   88  TI-CF07-88-TIPO-ROL-RECEPT  VALUE 'R'.                   
               10  TI-CF07-TRACE-ADQUIRIENTE       PIC  9(06).                  
               10  TI-CF07-CANAL-CCE               PIC  9(02).                  
               10  TI-CF07-BIN-ADQUIRIENTE         PIC  X(11).                  
               10  TI-CF07-TERMINAL-ID             PIC  X(08).                  
               10  TI-CF07-FECHA-TRANS.                                         
                   15  TI-CF07-FECHA-TRANS-MM      PIC  X(02).                  
                   15  TI-CF07-FECHA-TRANS-DD      PIC  X(02).                  
               10  TI-CF07-HORA-TRANS.                                          
                   15  TI-CF07-HORA-TRANS-HH       PIC  X(02).                  
                   15  TI-CF07-HORA-TRANS-MM       PIC  X(02).                  
                   15  TI-CF07-HORA-TRANS-SS       PIC  X(02).                  
      *----------------------------------------------------------------*        
      *        DETALLE ERROR                                                    
      *----------------------------------------------------------------*        
           05  TI-CF07-COD-ERROR                   PIC  X(06).                  
           05  TI-CF07-MSG-ERROR                   PIC  X(80).                  
           05  TI-CF07-ESTADO                      PIC  X(02).                  
               88  TI-CF07-88-ACEP                 VALUE '00'.                  
               88  TI-CF07-88-PEND                 VALUE '01'.                  
               88  TI-CF07-88-RECH                 VALUE '02'.                  
           05  TI-CF07-PROG                        PIC  X(08).                  
           05  TI-CF07-REG-CF06-TRANS              PIC  X(2200).                
           05  FILLER                              PIC  X(63).                  
      *----------------------------------------------------------------*        

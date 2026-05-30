      ******************************************************************        
      * COPY        : BCTICAR2                                         *        
      * APLICACION  : MODULO TTIB EN LINEA                             *        
      * DESCRIPCION : COMMAREA DE PROGRAMAS DE RECEPTOR VOCALINK       *        
      * L.R.        : 4500 BYTES                                       *        
      ******************************************************************        
      *                                                                *        
      *              C O N T R O L   D E   C A M B I O S               *        
      ******************************************************************        
      * MODIFICACION  : VOCALINK (BASADO EN BCTICA02)                  *        
      * FECHA         : 2022                                           *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: TCS                                            *        
      * NRO.TICKET    : TA000184140                                    *        
      *----------------------------------------------------------------*        
       01  TI-CAR2-AREA-COMUNICACION.                                           
                                                                                
           05  TI-CAR2-LONG-REG                    PIC S9(04) COMP.             
           05  TI-CAR2-LONG-REG-XX  REDEFINES                                   
               TI-CAR2-LONG-REG                    PIC  X(02).                  
           05  FILLER                              PIC  X(02).                  
           05  TI-CAR2-ID-AREA-TTIB                PIC  X(08).                  
               88  TI-CAR2-88-AREA-TTIB                VALUE '*TICAR2*'.        
                                                                                
      *   NEXT-DAY                                                              
           05  TI-CAR2-INFO-NEXT-DAY.                                           
               10  TI-CAR2-FLAG-NEXT-DAY           PIC  X(01).                  
                   88  TI-CAR2-88-CURRENT-DAY          VALUE '0'.               
                   88  TI-CAR2-88-IN-PROCESS           VALUE '7'.               
                   88  TI-CAR2-88-NEXT-DAY             VALUE '9'.               
      *   AREA DE ARCHIVOS                                                      
           05  TI-CAR2-FILES.                                                   
               10  TI-CAR2-FILE-NAME-MAESTRO       PIC  X(08).                  
               10  TI-CAR2-FILE-NAME-MAESTRO-ALT   PIC  X(08).                  
      *GNS-I                                                                    
      *        10  TI-CAR2-FILE-NAME-MAESTRO-ALT2  PIC  X(08).                  
               10  TI-CAR2-FILE-NAME-MAESTRO-ALT3  PIC  X(08).                  
      *GNS-F                                                                    
               10  TI-CAR2-FILE-NAME-EVEN-LOG      PIC  X(08).                  
      *GNS-I                                                                    
      *   AREA AUXILIAR                                                         
           05  TI-CAR2-AUTORIZAT-ID-RESP           PIC  9(06).                  
           05  TI-CAR2-REQUEST-ID-BCP.                                          
               10  TI-CAR2-BK-REQUEST-ID-BCP       PIC  X(03).                  
               10  TI-CAR2-NC-REQUEST-ID-BCP       PIC  9(09).                  
           05  TI-CAR2-COD-PROCESO-CNF-CAN         PIC  X(02).                  
               88  TI-CAR2-88-COD-PROCESO-CNF      VALUE '00'.                  
               88  TI-CAR2-88-COD-PROCESO-CAN      VALUE '05'.                  
           05  FILLER                              PIC  X(447).                 
      *GNS-F                                                                    
      *----------------------------------------------------------------*        
      *    SECCION: REGISTRO DE COMUNICACION CON MIDLEWARE TTIB        *        
      *----------------------------------------------------------------*        
           05  TI-CAR2-REG-TRANS.                                               
               10  TI-CAR2-REG-TRANS-DATA          PIC  X(4000).                

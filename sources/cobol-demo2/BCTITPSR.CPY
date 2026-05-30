      ******************************************************************        
      *    COPY        :  BCTITPSR                                     *        
      *    APLICATIVO  :  MODULO TTIB EN LINEA                         *        
      *    DESCRIPCION :  COPY SOLICITUD ESTADO DE PAGO                *        
      *                                                                *        
      *    LR          :  500 BYTES                                    *        
      ******************************************************************        
       01  TI-TPSR-TRAMA-VLK-TTIB.                                              
                                                                                
            05  TI-TPSR-IO-TRAMA.                                               
                10  TI-TPSR-SERV                  PIC  X(04).                   
                10  TI-TPSR-REQUEST               PIC  9(12).                   
                10  TI-TPSR-CREA-DATE             PIC  9(08).                   
                10  TI-TPSR-CREA-TIME             PIC  9(06).                   
                10  TI-TPSR-ORIC-DATE             PIC  9(08).                   
                10  TI-TPSR-ORIC-TIME             PIC  9(06).                   
                10  TI-TPSR-ENTIDAD-ORIGEN        PIC  9(04).                   
                10  TI-TPSR-ENTIDAD-RECEP         PIC  9(04).                   
                10  TI-TPSR-RESP-DATE             PIC  9(08).                   
                10  TI-TPSR-RESP-TIME             PIC  9(06).                   
                10  TI-TPSR-TERMINAL-ID           PIC  X(08).                   
                10  TI-TPSR-REFERENCIA            PIC  X(12).                   
                10  TI-TPSR-TRACE                 PIC  9(06).                   
                10  TI-TPSR-AMOUNT                PIC  9(12).                   
                10  TI-TPSR-CURRENCY              PIC  9(03).                   
                10  TI-TPSR-REF-TRAN              PIC  X(25).                   
                10  TI-TPSR-CODE-RET              PIC  9(02).                   
                10  TI-TPSR-CODE-RESAMP           PIC  X(04).                   
                10  TI-TPSR-COMISION              PIC  9(15).                   
                10  TI-TPSR-FECHA-LIQ             PIC  9(08).                   
                10  TI-TPSR-TRAN-EXT              PIC  9(03).                   
                10  TI-TPSR-ORI-CCI               PIC  X(20).                   
                10  TI-TPSR-REC-CCI               PIC  X(20).                   
                10  TI-TPSR-REC-TAR               PIC  X(20).                   
                10  TI-TPSR-MISMO-CLI             PIC  X(01).                   
                10  TI-TPSR-INSTR-ID              PIC  X(35).                   
                10  TI-TPSR-MONTO-LIQ             PIC  9(12).                   
                10  TI-TPSR-NRO-REINTENTOS        PIC  X(02).                   
                10  FILLER                        PIC  X(226).                  

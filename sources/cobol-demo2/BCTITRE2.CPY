      *----------------------------------------------------------------*        
      * COPY        : BCTITRE2                                         *        
      * APLICATIVO  : MODULO TTIB EN LINEA                             *        
      * MODULO      : ADMINISTRACION DE PARAMETROS                     *        
      * DESCRIPCION : TRAMA DE COMUNICACION CON SIX/STI DE NOVATRONIC  *        
      *             : NUEVA TRAMA COMUNICACION CON SIX/STI VOCALYNK    *        
      * ORGANIZACION: REFERENCIA DEL COPY BCTITR02                     *        
      * LONG.REG.   : 1540 BYTES NUEVA LONG. 4000                      *        
      *----------------------------------------------------------------*        
       01  TI-TRE2-TRAMA-SIX-TTIB.                                              
                                                                                
           05  TI-TRE2-I-TRAMA.                                                 
      *----------------------------------------------------------------*        
      *        SECCION: ISO                                                     
      *----------------------------------------------------------------*        
               10  TI-TRE2-CODIGO-SERVICIO             PIC  X(04).              
               10  TI-TRE2-MSGE-TYPE-ID                PIC  X(04).              
      *------- FECHA Y HORA DE PROCESO FORMATO MMDDHHMMSS -------------*        
               10  TI-TRE2-FECHA-HORA-PROC             PIC  9(06).              
               10  TI-TRE2-FECHA-PROCESO               PIC  9(08).              
               10  TI-TRE2-CANAL                       PIC  9(02).              
               10  TI-TRE2-NUMERO-REF-RECUPERACIO      PIC  X(12).              
               10  TI-TRE2-TRACE-ADQUIRIENTE           PIC  9(06).              
               10  TI-TRE2-RESPONSE-CODE-CCE           PIC  X(02).              
               10  TI-TRE2-TERMINAL-ID                 PIC  X(08).              
               10  TI-TRE2-COD-RESP-AMPLIADO           PIC  X(04).              
      *----------------------------------------------------------------*        
      *        SECCION: TRANSACCION                                             
      *----------------------------------------------------------------*        
               10  TI-TRE2-TRANS-EXTENDIDA             PIC  X(03).              
               10  TI-TRE2-IMPORTE                     PIC  9(12).              
               10  TI-TRE2-CONCEPT-COBRO-TARI          PIC  X(04).              
               10  TI-TRE2-CODIGO-TARIFA               PIC  X(04).              
               10  TI-TRE2-IMPORTE-COMISION            PIC  9(15).              
               10  TI-TRE2-CRITERIO-APLICACION         PIC  X(01).              
               10  TI-TRE2-REF-TRANSFERENCIA           PIC  X(25).              
               10  TI-TRE2-INDICADOR-PAG-HAB           PIC  X(01).              
               10  TI-TRE2-MES-PAGO                    PIC  X(02).              
               10  TI-TRE2-ANIO-PAGO                   PIC  X(04).              
               10  TI-TRE2-IMPORT-SUELDO-BRUTO         PIC  9(12).              
               10  TI-TRE2-TRANS-CURREN-CODE           PIC  9(03).              
      *----------------------------------------------------------------*        
      *        SECCION: EMISOR                                                  
      *----------------------------------------------------------------*        
               10  TI-TRE2-ENTIDAD-ORIGEN              PIC  X(04).              
               10  TI-TRE2-CCI-CLI-ORIGINANTE          PIC  X(20).              
               10  TI-TRE2-TIPO-PERSONA                PIC  X(01).              
               10  TI-TRE2-TIP-DOC-CLI-ORIG            PIC  X(01).              
               10  TI-TRE2-NRO-DOC-CLI-ORIG            PIC  X(12).              
               10  TI-TRE2-APE-PAT-RAZ-SOC-CLI-OR      PIC  X(140).             
               10  TI-TRE2-DIRECC-CLI-ORIG             PIC  X(70).              
               10  TI-TRE2-NRO-FIJO-CLI-ORIG           PIC  X(10).              
               10  TI-TRE2-NRO-CEL-CLI-ORIG            PIC  X(15).              
      *----------------------------------------------------------------*        
      *        SECCION: RECEPTOR                                                
      *----------------------------------------------------------------*        
               10  TI-TRE2-ENTIDAD-DESTINO             PIC  X(04).              
               10  TI-TRE2-CCI-CLI-BENEFICIA           PIC  X(20).              
               10  TI-TRE2-COD-TARJETA-CRED            PIC  X(20).              
               10  TI-TRE2-NRO-DOC-CLI-BENE            PIC  X(12).              
               10  TI-TRE2-TIP-DOC-CLI-BENE            PIC  X(01).              
               10  TI-TRE2-APE-PAT-RAZ-SOC-CLI-BE      PIC  X(140).             
               10  TI-TRE2-DIRECC-CLI-BENE             PIC  X(70).              
               10  TI-TRE2-TELEF-CLI-BENE              PIC  X(10).              
               10  TI-TRE2-NRO-CEL-CLI-BENE            PIC  X(15).              
               10  TI-TRE2-INDI-MISMO-CLIENTE          PIC  X(01).              
               10  TI-TRE2-CANAL-BCP                   PIC  X(02).              
               10  TI-TRE2-GLOSA-I                     PIC  X(140).             
               10  TI-TRE2-REF-INSTRUCTION-ID          PIC  X(35).              
               10  TI-TRE2-INSTRUCTION-ID              PIC  X(35).              
               10  TI-TRE2-INDI-REINTENTO              PIC  9(02).              
               10  TI-TRE2-REQUEST-ID                  PIC  X(12).              
               10  TI-TRE2-MONTO-LIQUIDAC-INTERB       PIC  X(12).              
               10  TI-TRE2-FECHA-LIQUIDACION           PIC  X(08).              
               10  TI-TRE2-FECHA-RESPUESTA             PIC  X(08).              
               10  TI-TRE2-FECHA-HORA-RESPUESTA        PIC  X(06).              
               10  TI-TRE2-VALOR-PROXY                 PIC  X(2048).            
               10  TI-TRE2-TIPO-PROXY                  PIC  X(35).              
               10  TI-TRE2-CODMSG-ESTRUCTURA           PIC  X(06).              
               10  TI-TRE2-VARMSG-FUN                  PIC  X(20).              
               10  TI-TRE2-VARMSG-RSO                  PIC  X(20).              
               10  TI-TRE2-VARMSG-ARG                  PIC  X(20).              
               10  TI-TRE2-VARMSG-TXT                  PIC  X(20).              
               10  TI-TRE2-VARMSG-OPE                  PIC  X(20).              
JCS            10  TI-TRE2-GLOSA-BCP                   PIC  X(30).              
JCS            10  TI-TRE2-CON-INSTRUCTION-ID          PIC  X(35).              
JCS            10  TI-TRE2-FILLER                      PIC  X(778).             

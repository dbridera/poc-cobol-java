      *----------------------------------------------------------------*        
      * COPY        : BCTITRR2                                         *        
      * APLICATIVO  : MODULO TTIB EN LINEA                             *        
      * MODULO      : ADMINISTRACION DE PARAMETROS                     *        
      * DESCRIPCION : TRAMA DE COMUNICACION RECEPTOR CON VOCALINK      *        
      * ORGANIZACION:                                                  *        
      * LONG.REG.   : 4000 BYTES                                       *        
      *----------------------------------------------------------------*        
      ******************************************************************        
      *                       CONTROL DE CAMBIOS                       *        
      ******************************************************************        
      * MODIFICACION  : ADICION LOS SIGUIENTES CAMPOS:                 *        
      *                 - TI-TRR2-GLOSA-BCP                            *        
      *                 - TI-TRR2-CON-INSTRUCTION-ID                   *        
      *                 - TI-TRR2-CODMSG-ESTRUCTURA                    *        
      *                 - TI-TRR2-MSJ-ERROR                            *        
      * FECHA         : 15-03-2023                                     *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: JCS                                            *        
      * NRO.TICKET    : MVP00127821                                    *        
      ******************************************************************        
                                                                                
       01  TI-TRR2-TRAMA-VLK-TTIB.                                              
                                                                                
           05  TI-TRR2-I-TRAMA.                                                 
      *----------------------------------------------------------------*        
      *        SECCION: ISO                                                     
      *----------------------------------------------------------------*        
               10  TI-TRR2-COD-SERV                    PIC  X(04).              
               10  TI-TRR2-REQUEST-ID                  PIC  X(12).              
               10  TI-TRR2-ENTIDAD-ORIGEN              PIC  X(08).              
               10  TI-TRR2-ENTIDAD-DESTINO             PIC  X(08).              
               10  TI-TRR2-CREATION-DATE               PIC  9(08).              
               10  TI-TRR2-CREATION-TIME               PIC  9(06).              
               10  TI-TRR2-TERMINAL-ID                 PIC  X(08).              
               10  TI-TRR2-NRO-REFERENCIA              PIC  X(12).              
               10  TI-TRR2-TRACE-ADQUIRIENTE           PIC  9(06).              
               10  TI-TRR2-NOM-APE-ORIG                PIC  X(140).             
               10  TI-TRR2-NRO-DOC-CLI-ORIG            PIC  X(12).              
               10  TI-TRR2-TIP-DOC-CLI-ORIG            PIC  X(01).              
               10  TI-TRR2-TELEF-CLI-ORIG              PIC  X(10).              
               10  TI-TRR2-DIRECC-CLI-ORIG             PIC  X(70).              
               10  TI-TRR2-NRO-CEL-CLI-ORIG            PIC  X(15).              
               10  TI-TRR2-TRANS-EXTENDIDA             PIC  X(03).              
               10  TI-TRR2-CANAL                       PIC  9(02).              
               10  TI-TRR2-DIRECC-CLI-BENE             PIC  X(70).              
               10  TI-TRR2-TELEF-CLI-BENE              PIC  X(10).              
               10  TI-TRR2-NRO-CEL-CLI-BENE            PIC  X(15).              
               10  TI-TRR2-CCI-CLI-BENEFICIA           PIC  X(20).              
               10  TI-TRR2-COD-TARJETA-CRED            PIC  X(20).              
               10  TI-TRR2-TIPO-PERSONA                PIC  X(01).              
               10  TI-TRR2-TRANS-CURREN-CODE           PIC  9(03).              
               10  TI-TRR2-INSTRUCTION-ID              PIC  X(35).              
               10  TI-TRR2-BRANCH-ID                   PIC  X(35).              
               10  TI-TRR2-RESPONSE-CODE-CCE           PIC  X(02).              
               10  TI-TRR2-COD-RESP-AMPLIADO           PIC  X(04).              
               10  TI-TRR2-NOM-APE-BENE                PIC  X(140).             
               10  TI-TRR2-NRO-DOC-CLI-BENE            PIC  X(12).              
               10  TI-TRR2-TIP-DOC-CLI-BENE            PIC  X(01).              
               10  TI-TRR2-INDI-MISMO-CLIENTE          PIC  X(01).              
               10  TI-TRR2-IMPORTE                     PIC  9(12).              
               10  TI-TRR2-REF-TRANSFERENCIA           PIC  X(25).              
               10  TI-TRR2-REF-INSTRUCTION-ID          PIC  X(35).              
               10  TI-TRR2-IMPORTE-COMISION            PIC  9(15).              
               10  TI-TRR2-CODIGO-TARIFA               PIC  X(04).              
               10  TI-TRR2-CRITERIO-APLICACION         PIC  X(01).              
               10  TI-TRR2-CCI-CLI-ORIGINANTE          PIC  X(20).              
               10  TI-TRR2-CONCEPT-COBRO               PIC  X(04).              
               10  TI-TRR2-GLOSA                       PIC  X(140).             
               10  TI-TRR2-IMPORT-SUELDO-BRUTO         PIC  9(12).              
               10  TI-TRR2-INDICADOR-PAG-HAB           PIC  X(01).              
               10  TI-TRR2-MES-PAGO                    PIC  X(02).              
               10  TI-TRR2-ANIO-PAGO                   PIC  X(04).              
               10  TI-TRR2-FECHA-LIQUIDACION           PIC  9(08).              
               10  TI-TRR2-MONTO-LIQUIDACION           PIC  9(12).              
               10  TI-TRR2-RESPONSE-DATE               PIC  9(08).              
               10  TI-TRR2-RESPONSE-TIME               PIC  9(06).              
               10  TI-TRR2-NUMERO-REINTENTOS           PIC  9(02).              
               10  TI-TRR2-TIPO-PROCESO                PIC  X(01).              
                   88  TI-TRR2-88-TIP-PROC-LINEA       VALUE 'L'.               
                   88  TI-TRR2-88-TIP-PROC-BATCH       VALUE 'B'.               
               10  TI-TRR2-REENVIO                     PIC  X(02).              
                   88  TI-TRR2-88-NO-REENV             VALUE '00'.              
                   88  TI-TRR2-88-SI-REENV             VALUE '01'.              
               10  TI-TRR2-PROXY-VALUE                 PIC  X(2048).            
               10  TI-TRR2-PROXY-TYPE                  PIC  X(35).              
               10  TI-TRR2-CODMSG-ESTRUCTURA           PIC  X(06).      127821  
               10  TI-TRR2-MSJ-ERROR                   PIC  X(100).     127821  
               10  TI-TRR2-GLOSA-BCP                   PIC  X(30).      127821  
               10  TI-TRR2-CON-INSTRUCTION-ID          PIC  X(35).      127821  
               10  TI-TRR2-LIBRE-RECEPTOR              PIC  X(738).     127821  
      *        10  TI-TRR2-LIBRE-RECEPTOR              PIC  X(909).     127821  

      ******************************************************************        
      * COPY        : BCTICA80                                         *        
      * APLICACION  : TRANSFERENCIA INTERBANCARIAS                     *        
      * MODULO      : TTIB EN LINEA                                    *        
      * DESCRIPCION : COMMAREA DEL PROGRAMA ENCARGADO DEL MANTENIMIEN- *        
      *             : TO DEL ARCHIVO DE PARAMETROS                     *        
      * L.R.        : 4400 BYTES                                       *        
      ******************************************************************        
       01  TI-CA80-COMMAREA.                                                    
      *                                                                         
           05  TI-CA80-ID-AREA-MPARAM                  PIC  X(08).              
               88  TI-CA80-88-MPARAMETROS              VALUE '*TICA80*'.        
      *    INFORMACION DE ENTRADA PARA LLAMAR AL MODULO                         
           05  TI-CA80-INPUT-MPARAM.                                            
               10  TI-CA80-I-TIPO-ACCION               PIC  X(01).              
                   88  TI-CA80-I-88-TACC-CONSULTAR     VALUE  'C'.              
                   88  TI-CA80-I-88-TACC-ADICIONAR     VALUE  'A'.              
                   88  TI-CA80-I-88-TACC-MODIFICAR     VALUE  'M'.              
                   88  TI-CA80-I-88-TACC-ELIMINAR      VALUE  'E'.              
      *    INFORMACION PARA INDICAR TIPO DE CONSULTA                            
               10  TI-CA80-I-TIPO-CONSULTA             PIC  X(01).              
                   88  TI-CA80-I-TCONS-SIMPLE          VALUE 'S'.               
                   88  TI-CA80-I-TCONS-MASIVA          VALUE 'M'.               
               10  TI-CA80-I-DISPONIBLE-01             PIC  X(48).              
      *    INFORMACION DEL REGISTRO A INGRESAR                                  
               10  TI-CA80-I-REG-MPARAM                PIC X(250).              
               10  TI-CA80-I-DISPONIBLE-02             PIC  X(92).              
      *    INFORMACION DE SALIDA DEL MODULO                                     
           05  TI-CA80-OUTPUT-MPARAM.                                           
               10  TI-CA80-O-RESULTADO.                                         
                   15  TI-CA80-O-RCODE.                                         
                       20  TI-CA80-O-RC-APL            PIC X(02).               
                       20  TI-CA80-O-RC-NRO.                                    
                           25  TI-CA80-O-RC-TIP            PIC X(02).           
                               88  TI-CA80-88-CONFORME     VALUE '00'.          
                               88  TI-CA80-88-CONSISTENCIA VALUE '04'.          
                               88  TI-CA80-88-RECURSOS     VALUE '08'.          
                               88  TI-CA80-88-INTERFACES   VALUE '12'.          
                               88  TI-CA80-88-AUTORIZACION VALUE '16'.          
                           25  TI-CA80-O-RC-SEC            PIC X(02).           
                               88  TI-CA80-RC-SEC-OK       VALUE '00'.          
                   15  TI-CA80-O-RC-MSG                    PIC X(80).           
      *                                                                         
               10  TI-CA80-O-NRO-REGISTROS                 PIC 9(02).           
               10  TI-CA80-O-DISPONIBLE-01                 PIC X(32).           
               10  TI-CA80-O-LISTA-PARAM    OCCURS 15 TIMES.                    
                   15  TI-CA80-O-REG-PARAM                 PIC X(250).          
               10  TI-CA80-O-DISPONIBLE-02                 PIC X(130).          

      ******************************************************************        
      * COPY        : BCTICA15                                         *        
      * APLICATIVO  : TTIB                                             *        
      * DESCRIPCION : COMUNICACION CON EL MODULO DE MENSAJES           *        
      * ORGANIZACION: COMMAREA                                         *        
      * L.R.        : 500 BYTES                                        *        
      ******************************************************************        
      *                                                                         
       01  TI-CA15-I-O-MENSAJES.                                                
      *----------------------------------------------------------------*        
      * TRAMA INPUT - OUTPUT PARA EL MODULO DE MENSAJES                *        
      *----------------------------------------------------------------*        
      *                                                                         
           05  TI-CA15-INPUT-MENSAJES.                                          
               10  TI-CA15-I-RCODE.                                             
                   15  TI-CA15-I-RC-APP                PIC  X(04).              
                       88 TI-CA15-I-RC-APP-CCE             VALUE 'CCE'.         
                       88 TI-CA15-I-RC-APP-TTIB            VALUE 'TTIB'.        
                   15  TI-CA15-I-RC-COD                PIC  X(06).              
               10  TI-CA15-I-TEXTO-MSG                 PIC  X(80).              
               10  TI-CA15-I-VARIABLES.                                         
                   15  TI-CA15-I-VAR-PROGRAMA          PIC  X(08).              
                   15  TI-CA15-I-VAR-FUNCION           PIC  X(20).              
                   15  TI-CA15-I-VAR-RECURSO           PIC  X(20).              
                   15  TI-CA15-I-VAR-ARGUMENTO         PIC  X(20).              
                   15  TI-CA15-I-VAR-TEXTO             PIC  X(55).              
                   15  TI-CA15-I-VAR-OPERACION         PIC  X(20).              
                   15  TI-CA15-I-VAR-LIBRE             PIC  X(30).              
                   15  TI-CA15-I-EIBRESP               PIC S9(08) COMP.         
                   15  TI-CA15-I-EIBRESP2              PIC S9(08) COMP.         
               10  TI-CA15-I-LIBRE                     PIC  X(50).              
                                                                                
           05  TI-CA15-OUTPUT-MENSAJES.                                         
               10  TI-CA15-O-CONTROL.                                           
                   15  TI-CA15-O-RCODE.                                         
                       20  TI-CA15-O-RC-APL            PIC  X(02).              
                       20  TI-CA15-O-RC-TIP            PIC  X(02).              
                           88  TI-CA15-O-88-CONFORME        VALUE '00'.         
                           88  TI-CA15-O-88-CONSISTENCIA    VALUE '04'.         
                           88  TI-CA15-O-88-RECURSOS        VALUE '08'.         
                           88  TI-CA15-O-88-INTERFACES      VALUE '12'.         
                           88  TI-CA15-O-88-AUTORIZACION    VALUE '16'.         
                       20  TI-CA15-O-RC-SEC            PIC  X(02).              
                   15  TI-CA15-O-RC-MSG                PIC  X(80).              
      *                                                                         
           05  TI-CA15-O-LIBRE                         PIC  X(94).              
                                                                                

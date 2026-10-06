/*
    Clase apex : Crea Casos desde Formulario WEB
    Test: SEIDOR_ServicioCasosComentarioTest
*/
@RestResource(urlMapping='/casosComentario/*')
global class SEIDOR_ServicioCasosComentario {
    
    @HttpPost
    global static void ingresarCaso() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String jsonRequest = req.requestBody.toString();
        RequestObj reqObj = (RequestObj) System.JSON.deserialize(jsonRequest, RequestObj.class);
        ResponseVO retorno = new ResponseVO();
        String valida = validarEntrada(reqObj);
        
        if(valida != 'OK') {
            retorno.mensaje = valida;
            res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            res.statusCode = 400;
        } else {
            try {
                //TODO: crear caso con logica de negocio
                Id idTipoRegistro;
                Case casoNuevo = new Case();
                if(reqObj.queQuieresComentar == 'Producto'){
                    System.debug('Producto');
                    idTipoRegistro = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Ticket_Consumidor').getRecordTypeId();
                    Contact contacto = SEIDOR_ConsultasSOQL.buscarContactoConsumidor(reqObj.rut);
                    if(contacto == null){
                        //crear contacto
                        contacto = SEIDOR_ConsultasSOQL.crearContactoConsumidor(reqObj.rut, reqObj.nombre, reqObj.apellidos, reqObj.email, reqObj.celular);
                    } else {
                        System.debug('Contacto encontrado->'+contacto);
                    }
                    Product2 producto = SEIDOR_ConsultasSOQL.buscarProducto(reqObj.codigoBarra);
                    if(producto != null){
                        casoNuevo.ProductId = producto.Id;
                    } 
                    casoNuevo.ContactId    = contacto != null ? contacto.Id : null;
                    casoNuevo.recordTypeId = idTipoRegistro;
                    String mensaje = 'Nombre: '   + reqObj.nombre    + '\n' +
                        'Apellido: ' + reqObj.apellidos + '\n' +
                        'Rut: '      + reqObj.rut       + '\n' +
                        'Email: '    + reqObj.email     + '\n' +
                        'Celular: '  + reqObj.celular   + '\n\n' +
                        'Mensaje: \n'+ reqObj.mensaje;
                    casoNuevo.Description  = mensaje; 
                    casoNuevo.tipo__c      = reqObj.tipoComentario;
                    casoNuevo.Subject      = 'Caso WEB - Comentario/Producto';
                    casoNuevo.Origin       = 'WEB';
                    casoNuevo              = SEIDOR_ConsultasSOQL.insertCaso(casoNuevo);
                } else {
                    idTipoRegistro = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Solicitud_Gestion').getRecordTypeId();
                    
                    String mensaje = 'Nombre: '   + reqObj.nombre    + '\n' +
                        			 'Apellido: ' + reqObj.apellidos + '\n' +
                        			 'Rut: '      + reqObj.rut       + '\n' +
                        			 'Email: '    + reqObj.email     + '\n' +
                        			 'Celular: '  + reqObj.celular   + '\n';
                    casoNuevo.recordTypeId = idTipoRegistro;
                    casoNuevo.Origin       = 'WEB';
                                        
                    switch on reqObj.queQuieresComentar {
            			when 'Quiero Ser Cliente' {
                            System.debug('Quiero Ser Cliente');
                            mensaje = mensaje + 
                                     'Pais: '          + reqObj.pais        + '\n' +
                           			 'Ciudad: '        + reqObj.ciudad      + '\n';
                            if(reqObj.pais == 'Chile'){
                                mensaje = mensaje +
                                     'Comuna: '        + reqObj.comuna      + '\n' +
                           			 'Calle: '         + reqObj.calle       + '\n' +
                           			 'Departamento: '  + reqObj.departamento+ '\n'; 
                                casoNuevo.tipo__C                  = 'SOLICITUD';
                                casoNuevo.CATEGORIA_DE_SERVICIO__c = 'CLIENTE / DERIVADO A DISTRIBUIDOR';
                            } else {
                                casoNuevo.tipo__C                  = 'CONSULTAS';
                                casoNuevo.CATEGORIA_DE_SERVICIO__c = 'EXPORTACIÓN';
                            }
                           	mensaje = mensaje +
                                     'Razon Social: '  + reqObj.razonSocial + '\n' +
                        			 'Giro: '          + reqObj.giro        + '\n\n' +
                        			 'Mensaje: \n'     + reqObj.mensaje;
                            
                            casoNuevo.Description        = mensaje;
                            casoNuevo.Subject            = 'Caso WEB - Comentario/Quiero Ser Cliente';
                            casoNuevo.Proceso_Cliente__c = 'QUIERO SER CLIENTE';
                        } 
                        when 'Promoción, muestra o cupón' {
                            System.debug('Promoción, muestra o cupón');
                            mensaje = mensaje + '\n Mensaje: \n' + reqObj.mensaje;
                            casoNuevo.Description = mensaje;
                            casoNuevo.Subject     = 'Caso WEB - Comentario/Promoción, muestra o cupón';
                            casoNuevo.Proceso_Cliente__c = 'PROMOCION - MUESTRA O CUPON';
                            casoNuevo.tipo__C                  = 'SOLICITUD';
                            casoNuevo.CATEGORIA_DE_SERVICIO__c = 'PROMOCION, MUESTRA O CUPON';
                            Account cuenta = SEIDOR_ConsultasSOQL.buscarCuenta(reqObj.rut);
                            if(cuenta != null){
                                casoNuevo.AccountId = cuenta.Id;
                            }
                        } 
                        when 'Medio Ambiente' {
                            System.debug('Medio Ambiente');
                            mensaje = mensaje + '\n Mensaje: \n' + reqObj.mensaje;
                            casoNuevo.Description              = mensaje;
                            casoNuevo.Subject                  = 'Caso WEB - Comentario/Medio Ambiente';
                            casoNuevo.Proceso_Cliente__c       = 'MEDIO AMBIENTE';
                            casoNuevo.tipo__C                  = 'SOLICITUD';
                            casoNuevo.CATEGORIA_DE_SERVICIO__c = 'MEDIO AMBIENTE';
                            Account cuenta = SEIDOR_ConsultasSOQL.buscarCuenta(reqObj.rut);
                            if(cuenta != null){
                                casoNuevo.AccountId = cuenta.Id;
                            }
                        } 
                        when 'Auspicio o Patrocinio' {
                            System.debug('Auspicio o Patrocinio');
                            mensaje = mensaje + '\n Mensaje: \n' + reqObj.mensaje;
                            casoNuevo.Description = mensaje;
                            casoNuevo.Subject     = 'Caso WEB - Comentario/Auspicio o Patrocinio';
                            casoNuevo.Proceso_Cliente__c = 'AUSPICIO/PATROCINO';
                            casoNuevo.tipo__C            = 'SOLICITUD';
                            casoNuevo.CATEGORIA_DE_SERVICIO__c = 'AUSPICIO';
                            Account cuenta = SEIDOR_ConsultasSOQL.buscarCuenta(reqObj.rut);
                            if(cuenta != null){
                                casoNuevo.AccountId = cuenta.Id;
                            }
                        } 
                        when 'Sitio Web' {
                            System.debug('Sitio Web');
                            mensaje = mensaje + '\n Mensaje: \n' + reqObj.mensaje;
                            casoNuevo.Description = mensaje;
                            casoNuevo.Subject     = 'Caso WEB - Comentario/Sitio Web';
                            casoNuevo.Proceso_Cliente__c = 'SITIO WEB';
                            casoNuevo.tipo__C            = 'CONSULTAS';
                            casoNuevo.CATEGORIA_DE_SERVICIO__c = 'TICKETS WEB';
                            Account cuenta = SEIDOR_ConsultasSOQL.buscarCuenta(reqObj.rut);
                            if(cuenta != null){
                                casoNuevo.AccountId = cuenta.Id;
                            }
                        } 
                        when 'Otro motivo' {
                            System.debug('Otro motivo');
                            mensaje                      = mensaje + '\n Mensaje: \n' + reqObj.mensaje;
                            casoNuevo.Description        = mensaje;
                            casoNuevo.Subject            = 'Caso WEB - Comentario/Otro motivo';
                            casoNuevo.Proceso_Cliente__c = 'OTRO MOTIVO';
                            casoNuevo.tipo__C            = 'CONSULTAS';
                            casoNuevo.CATEGORIA_DE_SERVICIO__c = 'OTRO';
                            
                            Account cuenta = SEIDOR_ConsultasSOQL.buscarCuenta(reqObj.rut);
                            if(cuenta != null){
                                casoNuevo.AccountId = cuenta.Id;
                            }
                        }
                    }
                    System.debug(casoNuevo);
                    casoNuevo = SEIDOR_ConsultasSOQL.insertCaso(casoNuevo);
                }
                
                res.statusCode = 200;
                retorno.mensaje = 'Caso creado con exito! ';
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            } catch(QueryException ex) {
                res.statusCode = 400;
                retorno.mensaje = 'Error al crear caso '+ex.getMessage();
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            } catch(Exception e) {
                res.statusCode = 400;
                retorno.mensaje = 'Error al ingresar Datos ->' + e.getMessage();
                System.debug(e.getMessage());
                System.debug(e.getStackTraceString());
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            }
        }        
    }
    
    private static String validarEntrada(RequestObj req) {
        String retorno = '';
        switch on req.queQuieresComentar {
            when 'Producto' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }  
            when 'Quiero Ser Cliente' {
                if(req.pais == null || req.pais == ''){
                    retorno = retorno + '- pais no puede ser null. ';
                } else {
                    if(req.pais == 'Chile'){
                        if(req.region == null || req.region == ''){
                            retorno = retorno + '- region no puede ser null. ';
                        }
                        if(req.comuna == null || req.comuna == ''){
                            retorno = retorno + '- comuna no puede ser null. ';
                        }
                        if(req.calle == null || req.calle == ''){
                            retorno = retorno + '- calle no puede ser null. ';
                        }
                        if(req.numero == null || req.numero == ''){
                            retorno = retorno + '- numero no puede ser null. ';
                        }
                    }
                                        
                }
                if(req.ciudad == null || req.ciudad == ''){
                    retorno = retorno + '- ciudad no puede ser null. ';
                }
                if(req.razonSocial == null || req.razonSocial == ''){
                    retorno = retorno + '- razonSocial no puede ser null. ';
                }
                if(req.giro == null || req.giro == ''){
                    retorno = retorno + '- giro no puede ser null. ';
                }
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when 'Promoción, muestra o cupón' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when 'Medio Ambiente' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when 'Auspicio o Patrocinio' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when 'Sitio Web' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when 'Otro motivo' {
                if(req.rut == null || req.rut == ''){
                    retorno = retorno + '- rut no puede ser null. ';
                }
                if(req.nombre == null || req.nombre == ''){
                    retorno = retorno + '- nombre no puede ser null. ';
                }
                if(req.apellidos == null || req.apellidos == ''){
                    retorno = retorno + '- apellidos no puede ser null. ';
                }
                if(req.email == null || req.email == ''){
                    retorno = retorno + '- email no puede ser null. ';
                }
                if(req.celular == null || req.celular == ''){
                    retorno = retorno + '- celular no puede ser null. ';
                }
                if(req.mensaje == null || req.mensaje == ''){
                    retorno = retorno + '- mensaje no puede ser null. ';
                }
            }
            when else {
                retorno = 'Opción ¿Qué quieres comentar?, no válida';
            }
        }
        if(retorno == ''){
            retorno = 'OK';
        } else {
            retorno = retorno;
        }
        return retorno;
    }
    
    global class RequestObj {
        public String queQuieresComentar;
        public String tipoComentario; //CONSULTA/COMENTARIO, PREGUNTA, FELICITACIONES
        public String codigoBarra;
        public String rut;
        public String nombre;
        public String apellidos;
        public String email;
        public String celular;
        public String mensaje;
        public String pais;
        public String razonSocial;
        public String giro;
        public String region;
        public String ciudad;
        public String comuna;
        public String calle;
        public String numero;
        public String departamento;        
    }
    
    global class ResponseVO{
        public String mensaje;
    }
}
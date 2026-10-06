/**
 * Test: SEIDOR_ServicioCasosReclamoTest
 */
@RestResource(urlMapping='/casosReclamo/*')
global class SEIDOR_ServicioCasosReclamo {
    
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
                System.debug('Reclamo '+reqObj);
                idTipoRegistro = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Ticket_Consumidor').getRecordTypeId();
                Contact contacto = SEIDOR_ConsultasSOQL.buscarContactoConsumidor(reqObj.rut);
                if(contacto == null){
                    //crear contacto
                    contacto = SEIDOR_ConsultasSOQL.crearContactoConsumidor(reqObj.rut, reqObj.nombre, reqObj.apellidos, reqObj.email, reqObj.celular);
                }
                Product2 producto = SEIDOR_ConsultasSOQL.buscarProducto(reqObj.codigoBarra);
                if(producto == null){
                    producto = SEIDOR_ConsultasSOQL.buscarProductoXDefecto();
                } 
                casoNuevo.productId = producto.Id;
                casonuevo.FECHA_DE_VENCIMIENTO__c = obtenerFecha(reqObj.fechaVencimiento);
                casoNuevo.ContactId    = contacto != null ? contacto.Id : null;
                casoNuevo.recordTypeId = idTipoRegistro;
                casoNuevo.tipo__c      = 'RECLAMO CONSUMIDOR';
                casoNuevo.Subject      = 'Caso WEB - Reclamo';
                casoNuevo.Origin       = 'WEB';
                casoNuevo.LOTE__c      = reqObj.lote;
                String mensaje = 'Producto: '             + reqObj.cualEsElProducto   + '\n' +
                    'Marca: '                + reqObj.marca              + '\n' +
                    'Código Barra: '         + reqObj.codigoBarra        + '\n' +
                    'Lote: '                 + reqObj.lote               + '\n' +
                    'Unidades Reclamadas: '  + reqObj.unidadesReclamadas + '\n' +
                    'Lugar de Compra: '      + reqObj.lugarCompra        + '\n' +
                    'Fecha de Vencimiento: ' + reqObj.fechaVencimiento   + '\n\n' +
                    'Nombre: '               + reqObj.nombre             + '\n' +
                    'Apellido: '             + reqObj.apellidos          + '\n' +
                    'Rut: '                  + reqObj.rut                + '\n' +
                    'Email: '                + reqObj.email              + '\n' +
                    'Celular: '              + reqObj.celular            + '\n' +
                    'País: '                 + reqObj.pais               + '\n' +
                    'Región: '               + reqObj.region             + '\n' +
                    'Ciudad: '               + reqObj.ciudad             + '\n' +
                    'Comuna: '               + reqObj.comuna             + '\n' +
                    'Calle: '                + reqObj.calle              + '\n' +
                    'Número: '               + reqObj.numero             + '\n' +
                    'Departamento: '         + reqObj.departamento       + '\n\n' +
                    'Mensaje: '  + reqObj.mensaje;
                casoNuevo.Description  = mensaje; 
                
                casoNuevo              = SEIDOR_ConsultasSOQL.insertCaso(casoNuevo);
                
                if(!String.isBlank(reqObj.archivo)){
                    Boolean resultado = SEIDOR_ConsultasSOQL.createContentDocument(reqObj.archivo, reqObj.nombreArchivo, casoNuevo.id);
                    System.debug('el archivo se creo '+resultado);
                }
                
                res.statusCode = 200;
                retorno.mensaje = 'Caso creado con exito!';
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
                              
            } catch(QueryException ex) {
                res.statusCode = 400;
                retorno.mensaje = 'Error al crear caso '+ex.getMessage();
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            } catch(Exception e) {
                res.statusCode = 400;
                retorno.mensaje = 'Error al ingresar Datos ->' + e.getMessage();
                res.responseBody = Blob.valueOf(JSON.serialize(retorno));
            }
        }        
    }
    
    private static Date obtenerFecha(String fechaString){
         
        List<String> partes = fechaString.split('-'); 
        
        Integer dia = Integer.valueOf(partes[0]);
        Integer mes = Integer.valueOf(partes[1]);
        Integer anio = Integer.valueOf(partes[2]);
        
        Date fechaFinal = Date.newInstance(anio, mes, dia);
        System.debug(fechaFinal); 
        return fechaFinal;

    }
    
    private static String validarEntrada(RequestObj req) {
        String retorno = '';
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
        if(req.codigoBarra == null || req.codigoBarra == ''){
            retorno = retorno + '- codigoBarra no puede ser null. ';
        }
        if(req.fechaVencimiento == null || req.fechaVencimiento == ''){
            retorno = retorno + '- fechaVencimiento no puede ser null. ';
        }
        
        if(retorno == ''){
            retorno = 'OK';
        } else {
            retorno = retorno;
        }
        return retorno;
    }
    
    global class RequestObj {
        public String cualEsElProducto;
        public String marca; 
        public String codigoBarra;
        public String lote;
        public Integer unidadesReclamadas;
        public String lugarCompra;
        public String fechaVencimiento;
        public String rut;
        public String nombre;
        public String apellidos;
        public String email;
        public String celular;
        public String pais;
        public String region;
        public String ciudad;
        public String comuna;
        public String calle;
        public String numero;
        public String departamento;
        public String archivo;
        public String nombreArchivo;
        public String mensaje;        
    }
    
    global class ResponseVO{
        public String mensaje;
    }
    
    
    

}
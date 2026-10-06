@isTest
public class SEIDOR_ServicioCasosComentarioTest {
    @TestSetup
    static void setupData(){
        Product2 c1 = new Product2(
            cgcloud__Consumer_Goods_Product_Code__c = '845541121',
            Name  = 'producto',
            cgcloud__Description_1_Language_1__c = 'Aceite coco 1000 Integraciones',
            cgcloud__State__c = '5',
             cgcloud__Container_Type__c='L',
            cgcloud__Product_Level__c= 'Product',
            Unidad_de_Medida__c= 'L',
            Vida_util__c= '548',
            Planta_Principal__c='SAN BERNARDO',
            Peso_Neto__c='1',
            Peso_Bruto__c=1,
            cgcloud__GTIN__c= '7802810012029'
        );
        insert c1;
    }
    
    @isTest
    static void testTipoProducto() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.tipoComentario = NULL; //CONSULTA/COMENTARIO, PREGUNTA, FELICITACIONES
        reqObj.codigoBarra = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        reqObj.pais = NULL;
        reqObj.razonSocial = NULL;
        reqObj.giro = NULL;

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Producto';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.tipoComentario = 'PREGUNTA';
        reqObj.codigoBarra    = '7802810012029';
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        System.debug(res.responseBody.toString());
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }
    
    @isTest
    static void testTipoQuieroSerCliente() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        reqObj.pais = NULL;
        reqObj.razonSocial = NULL;
        reqObj.giro = NULL;
        reqObj.region = NULL;
        reqObj.ciudad = NULL;
        reqObj.comuna = NULL;
        reqObj.calle = NULL;
        reqObj.numero = NULL;
        reqObj.departamento = NULL;  

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Quiero Ser Cliente';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.pais           = 'Argentina';
        reqObj.rut            = '9872018-9';
        reqObj.razonSocial    = 'Razón Social';
        reqObj.giro           = 'Giro';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.ciudad = 'Mendoza';        
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        reqObj.pais = 'Chile';        
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
                
        reqObj.pais   = 'Chile';
        reqObj.region = 'region';
        reqObj.ciudad = 'ciudad';
        reqObj.comuna = 'comuna';
        reqObj.calle = 'calle';
        reqObj.numero = 'numero';
        reqObj.departamento = 'departamento';          
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }
    
    @isTest
    static void testTipoPromocionMuestraCupon() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Promoción, muestra o cupón';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }

    @isTest
    static void testTipoMedioAmbiente() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Medio Ambiente';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }
    
    @isTest
    static void testTipoAuspicioPatrocinio() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Auspicio o Patrocinio';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }
    
    @isTest
    static void testTipoSitioWeb() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Sitio Web';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    } 
    
    @isTest
    static void testTipoOtroMotivo() {
        // Configuración del cuerpo de la solicitud con datos inválidos
        SEIDOR_ServicioCasosComentario.RequestObj reqObj = new SEIDOR_ServicioCasosComentario.RequestObj();
        reqObj.queQuieresComentar = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.mensaje = NULL;
        
        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.queQuieresComentar = 'Otro motivo';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.rut            = '9872018-9';
        reqObj.nombre         = 'Nombre';
        reqObj.apellidos      = 'Apellido';
        reqObj.email          = 'prueba@seidor.com';
        reqObj.celular        = '+56987878787';
        reqObj.mensaje        = 'prueba mensaje';
        req.requestBody       = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
		SEIDOR_ServicioCasosComentario.ingresarCaso();
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }

}
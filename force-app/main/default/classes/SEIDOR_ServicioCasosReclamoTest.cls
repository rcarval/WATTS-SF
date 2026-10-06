@isTest
public class SEIDOR_ServicioCasosReclamoTest {
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
        SEIDOR_ServicioCasosReclamo.RequestObj reqObj = new SEIDOR_ServicioCasosReclamo.RequestObj();
        reqObj.cualEsElProducto = NULL;
        reqObj.marca = NULL; 
        reqObj.codigoBarra = NULL;
        reqObj.lote = NULL;
        reqObj.unidadesReclamadas = NULL;
        reqObj.lugarCompra = NULL;
        reqObj.fechaVencimiento = NULL;
        reqObj.rut = NULL;
        reqObj.nombre = NULL;
        reqObj.apellidos = NULL;
        reqObj.email = NULL;
        reqObj.celular = NULL;
        reqObj.pais = NULL;
        reqObj.region = NULL;
        reqObj.ciudad = NULL;
        reqObj.comuna = NULL;
        reqObj.calle = NULL;
        reqObj.numero = NULL;
        reqObj.departamento = NULL;
        reqObj.archivo = NULL;
        reqObj.nombreArchivo = NULL;
        reqObj.mensaje = NULL; 

        Test.startTest();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosReclamo.ingresarCaso();
        System.assertEquals(400, res.statusCode);//NOPMD
        
        reqObj.cualEsElProducto = 'producto';
        reqObj.marca = 'Marca'; 
        reqObj.codigoBarra = '123';
        reqObj.lote = 'Lote';
        reqObj.unidadesReclamadas = 1;
        reqObj.lugarCompra = 'Lugar';
        reqObj.fechaVencimiento = '02-05-2026';
        reqObj.rut = '9727443-6';
        reqObj.nombre = 'NULL';
        reqObj.apellidos = 'NULL';
        reqObj.email = 'prueba@prueba.cl';
        reqObj.celular = 'NULL';
        reqObj.pais = 'NULL';
        reqObj.region = 'NULL';
        reqObj.ciudad = 'NULL';
        reqObj.comuna = 'NULL';
        reqObj.calle = 'NULL';
        reqObj.numero = '12';
        reqObj.departamento = 'NULL';
        reqObj.archivo = 'NULL';
        reqObj.nombreArchivo = 'NULL';
        reqObj.mensaje = 'NULL'; 
        
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosReclamo.ingresarCaso();
        system.debug('1.-'+res);
        System.debug('2.-'+res.responseBody.toString());
        //System.assertEquals(200, res.statusCode);//NOPMD
        
        reqObj.codigoBarra = '7802810012029';
        req.requestBody = Blob.valueOf(JSON.serialize(reqObj));
        RestContext.request = req;
        RestContext.response = res;
        SEIDOR_ServicioCasosReclamo.ingresarCaso();
        system.debug('3.-'+res);
        System.debug('4.-'+res.responseBody.toString());
        System.assertEquals(200, res.statusCode);//NOPMD
        
        Test.stopTest();
    }
}
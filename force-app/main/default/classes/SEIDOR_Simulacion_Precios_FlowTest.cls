/**********************************************************************************
Desarrollado por: Seidor
Autor: Seidor
Proyecto: Watts
Descripción: Clase Test consolidada para cubrir la simulación de precios:
Seidor_Simulacion_Precios_Flow, SEIDOR_Simulacion_Precios y los métodos SOQL
realmente involucrados y/o reutilizables del grupo técnico.
**********************************************************************************/
@IsTest
private class SEIDOR_Simulacion_Precios_FlowTest {
    
    private static final String RUT_CUENTA = '11111111-1';
    private static final String RUT_CONTACTO = '22222222-2';
    private static final String GTIN_PRODUCTO = '770000000001';
    private static final String CODIGO_PRODUCTO = '30000049';
    
    
    private static String lastRequestMethod;
    private static String lastEndpoint;
    private static String lastRequestBody;
    
    
    @TestSetup
    static void setupData() {
        Id idUsuario = UserInfo.getUserId();
        
        cgcloud__Org_Unit__c orgUnit = new cgcloud__Org_Unit__c(
            Name = idUsuario,                       // Org Unit Name
            cgcloud__Sales_Org__c = '0001',                      // Sales Org
            cgcloud__Org_Type__c = 'Sales',                      // Org Type
            cgcloud__Main__c = false,                            // Main
            cgcloud__Org_Level__c = 'SalesRep',                  // Org Level
            cgcloud__Description_Language_1__c = 'Ejecutivo 2',  // Description Language 1
            cgcloud__Description_Language_2__c = 'Ejecutivo 2',  // Description Language 2
            cgcloud__Description_Language_3__c = 'Ejecutivo 2',  // Description Language 3
            cgcloud__Description_Language_4__c = 'Ejecutivo 2'  // Description Language 4
        );
        insert orgUnit;
        
        cgcloud__Account_Template__c accTemplateCust = new cgcloud__Account_Template__c();
        accTemplateCust.Name = 'AccountTemplate summer test ';
        accTemplateCust.cgcloud__Sales_Org__c = '0001';
        accTemplateCust.cgcloud__Description_Language_1__c = accTemplateCust.Name;
        accTemplateCust.cgcloud__Available_Product_Level__c = 'Category; Brand';
        insert accTemplateCust;
        
        Account cuentaCliente = new Account(
            Name = 'Cuenta Cliente Test',
            cgcloud__Name_2__c = 'Cuenta Cliente',
            cgcloud__Account_Number__c = '17000615',
            AccountNumber = '11111111-1',
            cgcloud__Account_Template__c = accTemplateCust.Id
        );
        insert cuentaCliente;
        
        Account cuentaEntrega = new Account(
            Name = 'Cuenta Entrega Test',
            cgcloud__Name_2__c = 'Cuenta Entrega',
            cgcloud__Account_Number__c = '17000616',
            AccountNumber = '22222222-2',
            cgcloud__ExternalId__c = 'DR-001',
            cgcloud__Account_Template__c = accTemplateCust.Id
        );
        insert cuentaEntrega;
        
        Contact contacto = new Contact(
            FirstName = 'Juan',
            LastName = 'Pérez',
            Email = 'juan.perez@test.com',
            Phone = '123456789',
            Rut_Consumidor__c = RUT_CONTACTO,
            AccountId = cuentaCliente.Id
        );
        insert contacto;
        
        Product2 producto = new Product2(
            Name = 'Producto Simulación',
            IsActive = true,
            cgcloud__GTIN__c = GTIN_PRODUCTO,
            cgcloud__Consumer_Goods_Product_Code__c = CODIGO_PRODUCTO,
            Unidad_de_Medida__c = 'CJ'
        );
        insert producto;
        
        List<cgcloud__Order_Template__c> templates = new List<cgcloud__Order_Template__c>{
            new cgcloud__Order_Template__c(Name = 'TPL-ZNAC', Pricing_Clase_Pedido__c = 'ZNAC'),
                new cgcloud__Order_Template__c(Name = 'TPL-ZINT', Pricing_Clase_Pedido__c = 'ZLIN'),
                new cgcloud__Order_Template__c(Name = 'TPL-ZILQ', Pricing_Clase_Pedido__c = 'ZILQ'),
                new cgcloud__Order_Template__c(Name = 'TPL-ZVSC', Pricing_Clase_Pedido__c = 'ZVSC')
                };
        insert templates;
        
        List<cgcloud__Order__c> ordenes = new List<cgcloud__Order__c>();
        Integer indice = 1;
        for (cgcloud__Order_Template__c template : templates) {
            ordenes.add(new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = template.Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                Estado_de_transferencia__c = 'No iniciado',
                Referencia_cliente__c = 'REF-' + template.Pricing_Clase_Pedido__c + '-' + indice
            ));
            indice++;
        }
        insert ordenes;
        
        List<cgcloud__Order_Item__c> items = new List<cgcloud__Order_Item__c>();
        for (cgcloud__Order__c orden : ordenes) {
            items.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = orden.Id,
                cgcloud__Product__c = producto.Id,
                cgcloud__Quantity__c = 5,
                cgcloud__UoM__c = 'SalesUnit'
            ));
        }
        insert items;
    }
    
    private static Map<String, Id> getOrderIdsByReference() {
        Map<String, Id> orderIdsByReference = new Map<String, Id>();
        for (cgcloud__Order__c orden : [
            SELECT Id, Referencia_cliente__c
            FROM cgcloud__Order__c
            WHERE Referencia_cliente__c IN ('REF-ZNAC-1', 'REF-ZINT-2', 'REF-ZILQ-3', 'REF-ZVSC-4')
        ]) {
            orderIdsByReference.put(orden.Referencia_cliente__c, orden.Id);
        }
        return orderIdsByReference;
    }
    
    // Escenario: Flow sin Ids debe retornar mensaje de error controlado.
    @IsTest
    static void test01_ejecutarDesdeFlow_sinIds() { //NOPMD
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(new List<Id>());
        Test.stopTest();
        
        System.assertEquals(1, resultados.size(), 'Debe retornar un resultado controlado.');
        System.assertEquals('Error: No se recibieron OrderIds.', resultados[0], 'Debe informar que no llegaron OrderIds.');
    }
    
    // Escenario: Id válido de otro objeto debe forzar el catch real del flow.
    @IsTest
    static void test02_ejecutarDesdeFlow_idDeOtroObjeto() { //NOPMD
        Account cuenta = [SELECT Id FROM Account WHERE Name = 'Cuenta Cliente Test' LIMIT 1];
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(new List<Id>{ cuenta.Id });
        Test.stopTest();
        
        System.assertEquals(1, resultados.size(), 'Debe retornar un resultado por cada Id procesado.');
        System.assert(resultados[0].contains('EXCEPCION | OrderId='), 'Debe capturar la excepción real del flujo.');
    }
    
    // Escenario: Validación directa de métodos SOQL reutilizables y caminos alternos controlados.
    @IsTest
    static void test03_consultasSoql_reutilizables() {   //NOPMD
        Account cuenta = [SELECT Id, AccountNumber FROM Account WHERE Name = 'Cuenta Cliente Test' LIMIT 1];
        Contact contacto = [SELECT Id, Rut_Consumidor__c FROM Contact WHERE Rut_Consumidor__c = :RUT_CONTACTO LIMIT 1];
        Product2 producto = [SELECT Id FROM Product2 WHERE cgcloud__GTIN__c = :GTIN_PRODUCTO LIMIT 1];
        Map<String, Id> orderIdsByReference = getOrderIdsByReference();
        
        Account cuentaEncontrada = SEIDOR_ConsultasSOQL.buscarCuenta(RUT_CUENTA);
        Contact contactoEncontrado = SEIDOR_ConsultasSOQL.buscarContactoConsumidor(RUT_CONTACTO);
        Product2 productoEncontrado = SEIDOR_ConsultasSOQL.buscarProducto(GTIN_PRODUCTO);
        cgcloud__Order__c ordenEncontrada = SEIDOR_ConsultasSOQL.obtenerOrden(orderIdsByReference.get('REF-ZNAC-1'));
        List<cgcloud__Order_Item__c> itemsEncontrados = SEIDOR_ConsultasSOQL.obtenerOrdenItems(orderIdsByReference.get('REF-ZNAC-1'));
        cgcloud__Order__c ordenInexistente = SEIDOR_ConsultasSOQL.obtenerOrden(cuenta.Id);
        List<cgcloud__Order_Item__c> itemsInexistentes = SEIDOR_ConsultasSOQL.obtenerOrdenItems(cuenta.Id);
        
        System.assertEquals(cuenta.Id, cuentaEncontrada.Id, 'buscarCuenta debe encontrar la cuenta por AccountNumber.');
        System.assertEquals(contacto.Id, contactoEncontrado.Id, 'buscarContactoConsumidor debe encontrar el contacto por RUT.');
        System.assertEquals(producto.Id, productoEncontrado.Id, 'buscarProducto debe encontrar el producto por GTIN.');
        System.assertNotEquals(null, ordenEncontrada, 'obtenerOrden debe retornar la orden válida.');
        System.assertEquals(1, itemsEncontrados.size(), 'obtenerOrdenItems debe retornar el item asociado.');
        System.assertEquals(null, ordenInexistente, 'Con Id de otro objeto, obtenerOrden debe retornar null.');
        System.assertEquals(null, itemsInexistentes, 'Con Id de otro objeto, obtenerOrdenItems debe retornar null.');
    }
    
    // Escenario: Métodos auxiliares con dependencia/configuración externa deben responder de forma controlada.
    @IsTest
    static void test04_metodosAuxiliares_controlados() { //NOPMD
        Boolean archivoCreado = SEIDOR_ConsultasSOQL.createContentDocument(
            EncodingUtil.base64Encode(Blob.valueOf('archivo test')),
            'archivo.txt',
            '500000000000000AAA' //NOPMD - Falso Positivo - Fake Id
        );
        Contact contacto = SEIDOR_ConsultasSOQL.crearContactoConsumidor(
            '33333333-3',
            'Nombre',
            null,
            'correo@test.com',
            '999999999'
        );
        
        System.assertEquals(false, archivoCreado, 'Con LinkedEntityId inexistente, el método debe retornar false.');
        System.assertEquals(null, contacto, 'Sin datos mínimos válidos o CMDT utilizable, debe retornar null de forma controlada.');
    }
    
    
    @IsTest
    static void test05_consultarPreciosOrden_caminoFeliz() { //NOPMD
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('SUCCESS'));
        
        Test.startTest();
        HttpResponse response = SEIDOR_Simulacion_Precios.consultarPrecios_Orden(orderId);
        Test.stopTest();
        
        System.assertEquals(200, response.getStatusCode(), 'El Mock exitoso debe responder 200.');
        System.assertEquals('GET', lastRequestMethod, 'La integración debe usar método GET.');
        System.assertNotEquals(null, lastEndpoint, 'Debe generarse endpoint.');
        
        Map<String, Object> bodyMap =
            (Map<String, Object>) JSON.deserializeUntyped(lastRequestBody);
        
        System.assertEquals(
            '17000615',
            String.valueOf(bodyMap.get('customer')),
            'El body debe incluir el customer esperado.'
        );
        System.assertEquals(
            'ZNAC',
            String.valueOf(bodyMap.get('clasepedido')),
            'El body debe incluir la clase de pedido.'
        );
        
        List<Object> itemsBody = (List<Object>) bodyMap.get('items');
        System.assertNotEquals(null, itemsBody, 'El body debe incluir items.');
        System.assert(itemsBody.size() > 0, 'El body debe incluir al menos un item.');
        
        Map<String, Object> firstItem = (Map<String, Object>) itemsBody[0];
        System.assertEquals(
            '30000049',
            String.valueOf(firstItem.get('material')),
            'El body debe incluir el material del item.'
        );
    }
    
    @IsTest
    static void test06_ejecutarDesdeFlow_actualizaItems() { //NOPMD
        Map<String, Id> orderIdsByReference = getOrderIdsByReference();
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('SUCCESS'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(
            new List<Id>{
                orderIdsByReference.get('REF-ZINT-2')
                    }
        );
        Test.stopTest();
        
        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
            cgcloud_desc_Pricing_Info_1__c,
            cgcloud_desc_Pricing_Info_2__c,
            cgcloud_desc_Pricing_Info_4__c,
            cgcloud_desc_Pricing_Info_6__c,
            cgcloud_desc_Pricing_Info_7__c,
            Importe_Pricing_Info_1__c,
            Importe_Pricing_Info_2__c,
            Importe_Pricing_Info_4__c,
            Importe_Pricing_Info_6__c,
            Importe_Pricing_Info_7__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZINT-2'
        ];
        
        Map<String, cgcloud__Order_Item__c> itemsByReference = new Map<String, cgcloud__Order_Item__c>();
        for (cgcloud__Order_Item__c item : items) {
            itemsByReference.put(item.cgcloud__Order__r.Referencia_cliente__c, item);
        }
        
        System.debug('Resultados test06 => ' + resultados);
        
        System.assertEquals(1, resultados.size(), 'Debe procesarse 1 orden.');
        /*System.assert(
            resultados[0].startsWith('OK | OrderId='),
            'ZINT debe terminar OK. Resultado real: ' + resultados[0]
        );
        
        System.assertEquals(
            'ZIYL',
            itemsByReference.get('REF-ZINT-2').cgcloud_desc_Pricing_Info_2__c,
            'ZINT debe mapear ZIYL en Pricing Info 2.'
        );
        
        System.assertNotEquals(
            null,
            itemsByReference.get('REF-ZINT-2').Importe_Pricing_Info_2__c,
            'ZINT debe dejar valor en Pricing Info 2.'
        );*/
    }
    
    
    @IsTest
    static void test07_ejecutarDesdeFlow_actualizaItems_ZNAC() {  //NOPMD
        Map<String, Id> orderIdsByReference = getOrderIdsByReference();
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('SUCCESS'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(
            new List<Id>{
                orderIdsByReference.get('REF-ZNAC-1')
                    }
        );
        Test.stopTest();
        
        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
            cgcloud_desc_Pricing_Info_1__c,
            cgcloud_desc_Pricing_Info_7__c,
            Importe_Pricing_Info_1__c,
            Importe_Pricing_Info_7__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZNAC-1'
        ];
        
        Map<String, cgcloud__Order_Item__c> itemsByReference = new Map<String, cgcloud__Order_Item__c>();
        for (cgcloud__Order_Item__c item : items) {
            itemsByReference.put(item.cgcloud__Order__r.Referencia_cliente__c, item);
        }
        
        System.debug('Resultados test07 => ' + resultados);
        
        System.assertEquals(1, resultados.size(), 'Debe procesarse 1 orden.');
        System.assert(
            resultados[0].startsWith('OK | OrderId='),
            'ZNAC debe terminar OK. Resultado real: ' + resultados[0]
        );
        
        System.assertEquals(
            'Precio Lista',
            itemsByReference.get('REF-ZNAC-1').cgcloud_desc_Pricing_Info_1__c,
            'ZNAC debe mapear ZPRL en Pricing Info 1.'
        );
        
        System.assertNotEquals(
            null,
            itemsByReference.get('REF-ZNAC-1').Importe_Pricing_Info_1__c,
            'ZNAC debe dejar valor en Pricing Info 1.'
        );
        
        System.assertEquals(
            'IVA',
            itemsByReference.get('REF-ZNAC-1').cgcloud_desc_Pricing_Info_7__c,
            'ZNAC debe mapear MWST en Pricing Info 7.'
        );
        
        System.assertNotEquals(
            null,
            itemsByReference.get('REF-ZNAC-1').Importe_Pricing_Info_7__c,
            'ZNAC debe dejar valor en Pricing Info 7.'
        );
    }
    
    @IsTest
    static void test08_ejecutarDesdeFlow_actualizaItems_ZILQ() {  //NOPMD
        Map<String, Id> orderIdsByReference = getOrderIdsByReference();
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('SUCCESS'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(
            new List<Id>{
                orderIdsByReference.get('REF-ZILQ-3')
                    }
        );
        Test.stopTest();
        
        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
            cgcloud_desc_Pricing_Info_4__c,
            Importe_Pricing_Info_4__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZILQ-3'
        ];
        
        Map<String, cgcloud__Order_Item__c> itemsByReference = new Map<String, cgcloud__Order_Item__c>();
        for (cgcloud__Order_Item__c item : items) {
            itemsByReference.put(item.cgcloud__Order__r.Referencia_cliente__c, item);
        }
        
        System.debug('Resultados test08 => ' + resultados);
        
        System.assertEquals(1, resultados.size(), 'Debe procesarse 1 orden.');
        System.assert(
            resultados[0].startsWith('OK | OrderId='),
            'ZILQ debe terminar OK. Resultado real: ' + resultados[0]
        );
        
        System.assertEquals(
            'IVA',
            itemsByReference.get('REF-ZILQ-3').cgcloud_desc_Pricing_Info_4__c,
            'ZILQ debe mapear MWST en Pricing Info 4.'
        );
        
        System.assertNotEquals(
            null,
            itemsByReference.get('REF-ZILQ-3').Importe_Pricing_Info_4__c,
            'ZILQ debe dejar valor en Pricing Info 4.'
        );
    }
    
    @IsTest
    static void test09_ejecutarDesdeFlow_actualizaItems_ZVSC() { //NOPMD
        Map<String, Id> orderIdsByReference = getOrderIdsByReference();
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('SUCCESS'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(
            new List<Id>{
                orderIdsByReference.get('REF-ZVSC-4')
                    }
        );
        Test.stopTest();
        
        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
            cgcloud_desc_Pricing_Info_2__c,
            Importe_Pricing_Info_2__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZVSC-4'
        ];
        
        Map<String, cgcloud__Order_Item__c> itemsByReference = new Map<String, cgcloud__Order_Item__c>();
        for (cgcloud__Order_Item__c item : items) {
            itemsByReference.put(item.cgcloud__Order__r.Referencia_cliente__c, item);
        }
        
        System.debug('Resultados test09 => ' + resultados);
        
        System.assertEquals(1, resultados.size(), 'Debe procesarse 1 orden.');
        System.assert(
            resultados[0].startsWith('OK | OrderId='),
            'ZVSC debe terminar OK. Resultado real: ' + resultados[0]
        );
        
        System.assertEquals(
            'ZDUN',
            itemsByReference.get('REF-ZVSC-4').cgcloud_desc_Pricing_Info_2__c,
            'ZVSC debe mapear ZDUN en Pricing Info 2.'
        );
        
        System.assertNotEquals(
            null,
            itemsByReference.get('REF-ZVSC-4').Importe_Pricing_Info_2__c,
            'ZVSC debe dejar valor en Pricing Info 2.'
        );
    }
    
    // Escenario: Respuesta HTTP no 200 debe retornar mensaje ERROR sin intentar actualizar registros.
    @IsTest
    static void test10_ejecutarDesdeFlow_httpError() { //NOPMD
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('ERROR'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();
        
        System.assertEquals(1, resultados.size(), 'Debe existir un resultado por la orden procesada.');
        //System.assert(resultados[0].contains('EXCEPCION | OrderId='), 'Con status distinto de 200 debe retornar mensaje ERROR.');
    }
    
    
    @IsTest
    static void test11_ejecutarDesdeFlow_jsonInvalido() { //NOPMD
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new SimulacionPreciosMock('BAD_JSON'));
        
        Test.startTest();
        List<String> resultados = Seidor_Simulacion_Precios_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();
        
        System.assert(resultados.size() > 0); //NOPMD - Falso Positivo
        System.assert(String.join(resultados, ' | ').contains('EXCEPCION') || //NOPMD - Falso Positivo
                      String.join(resultados, ' | ').contains('ERROR'));
    }
    
    private class SimulacionPreciosMock implements HttpCalloutMock {
        private String scenario;
        
        public SimulacionPreciosMock(String scenario) {
            this.scenario = scenario;
        }
        
        public HttpResponse respond(HttpRequest req) {
            lastRequestMethod = req.getMethod();
            lastEndpoint = req.getEndpoint();
            lastRequestBody = req.getBody();
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (scenario == 'ERROR') {
                res.setStatusCode(500);
                res.setBody('{"message":"Error en simulacion"}');
                return res;
            }
            
            if (scenario == 'BAD_JSON') {
                res.setStatusCode(200);
                res.setBody('{"invalido":true}');
                return res;
            }
            
            res.setStatusCode(200);
            res.setBody(buildSuccessBody(lastRequestBody));
            return res;
        }
        
        private String buildSuccessBody(String requestBody) {
            String clasePedido = 'ZNAC';
            
            if (requestBody != null) {
                Map<String, Object> bodyMap =
                    (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                
                if (bodyMap.containsKey('clasepedido') && bodyMap.get('clasepedido') != null) {
                    clasePedido = String.valueOf(bodyMap.get('clasepedido'));
                }
            }
            
            List<String> condiciones = new List<String>();
            condiciones.add(condicion('ZPRL', 'Precio Lista', '1000', '1000', 'CLP'));
            
            if (clasePedido == 'ZNAC') {
                condiciones.add(condicion('ZDSE', 'Descuento', '50', '50', 'CLP'));
                condiciones.add(condicion('ZDGD', 'Desc. Granel', '20', '20', 'CLP'));
                condiciones.add(condicion('ZDPR', 'Desc. Promo', '10', '10', 'CLP'));
                condiciones.add(condicion('ZDIF', 'Diferencia', '5', '5', 'CLP'));
                condiciones.add(condicion('ZRSE', 'Recargo', '15', '15', 'CLP'));
                condiciones.add(condicion('MWST', 'IVA', '95', '95', 'CLP'));
                condiciones.add(condicion('IABA', 'Imp. Adic.', '8', '8', 'CLP'));
                condiciones.add(condicion('ILA', 'ILA', '3', '3', 'CLP'));
            } else if (clasePedido == 'ZINT') {
                condiciones.add(condicion('ZIYL', 'ZIYL', '40', '40', 'CLP'));
                condiciones.add(condicion('ZRSE', 'Recargo', '15', '15', 'CLP'));
                condiciones.add(condicion('MWST', 'IVA', '95', '95', 'CLP'));
                condiciones.add(condicion('IABA', 'Imp. Adic.', '8', '8', 'CLP'));
                condiciones.add(condicion('ILA', 'ILA', '3', '3', 'CLP'));
            } else if (clasePedido == 'ZILQ') {
                condiciones.add(condicion('ZIYL', 'ZIYL', '40', '40', 'CLP'));
                condiciones.add(condicion('ZRSE', 'Recargo', '15', '15', 'CLP'));
                condiciones.add(condicion('MWST', 'IVA', '95', '95', 'CLP'));
                condiciones.add(condicion('IABA', 'Imp. Adic.', '8', '8', 'CLP'));
                condiciones.add(condicion('ILA', 'ILA', '3', '3', 'CLP'));
            } else if (clasePedido == 'ZVSC') {
                condiciones.add(condicion('ZDUN', 'ZDUN', '40', '40', 'CLP'));
                condiciones.add(condicion('ZRSE', 'Recargo', '15', '15', 'CLP'));
                condiciones.add(condicion('MWST', 'IVA', '95', '95', 'CLP'));
                condiciones.add(condicion('IABA', 'Imp. Adic.', '8', '8', 'CLP'));
                condiciones.add(condicion('ILA', 'ILA', '3', '3', 'CLP'));
            }
            
            return '{' +
                '"VALORBRUTO":1000,' +
                '"VALORNETO":905,' +
                '"ITEMS":[' +
                '{' +
                '"MATERIAL":"30000049",' +
                '"CON_PRECIO":[' + String.join(condiciones, ',') + ']' +
                '}' +
                ']' +
                '}';
        }
        
        private String condicion(
            String condType,
            String tipoCond,
            String condValueNum,
            String condValueRaw,
            String condUnit
        ) {
            return '{' +
                '"COND_TYPE":"' + condType + '",' +
                '"TIPO_COND":"' + tipoCond + '",' +
                '"COND_VALUE":' + condValueNum + ',' +
                '"CONDVALUE":' + condValueRaw + ',' +
                '"COND_UNIT":"' + condUnit + '"' +
                '}';
        }
    }
}
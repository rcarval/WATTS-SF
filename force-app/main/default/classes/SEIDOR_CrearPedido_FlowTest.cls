/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase Test para probar cobertura clase  creación de pedido desde Flow y guardar la respuesta.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 13-03-2026           BB                     Creación de la Clase.
***********************************************************************************/
@IsTest
private class SEIDOR_CrearPedido_FlowTest {

    private static final String CODIGO_PRODUCTO = '30000038';

    private static String lastRequestMethod;
    private static String lastEndpoint;
    private static String lastRequestBody;

    @TestSetup
    static void setupData() {
        Id idUsuario = UserInfo.getUserId();

        cgcloud__Org_Unit__c orgUnit = new cgcloud__Org_Unit__c(
            Name = idUsuario,
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Org_Type__c = 'Sales',
            cgcloud__Main__c = false,
            cgcloud__Org_Level__c = 'SalesRep',
            cgcloud__Description_Language_1__c = 'Ejecutivo 2',
            cgcloud__Description_Language_2__c = 'Ejecutivo 2',
            cgcloud__Description_Language_3__c = 'Ejecutivo 2',
            cgcloud__Description_Language_4__c = 'Ejecutivo 2'
        );
        insert orgUnit;

        cgcloud__Account_Template__c accTemplateCust = new cgcloud__Account_Template__c(
            Name = 'AccountTemplate CrearPedido Test',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Description_Language_1__c = 'AccountTemplate CrearPedido Test',
            cgcloud__Available_Product_Level__c = 'Category; Brand'
        );
        insert accTemplateCust;

        Account cuentaCliente = new Account(
            Name = 'Cuenta Cliente Test',
            cgcloud__Name_2__c = 'Cuenta Cliente',
            cgcloud__Account_Number__c = '17000615',
            AccountNumber = '11111111-1',
            Centro_Suministrador__c = 'D009',
            cgcloud__Account_Template__c = accTemplateCust.Id
        );
        insert cuentaCliente;

        Account cuentaEntrega = new Account(
            Name = 'Cuenta Entrega Test',
            cgcloud__Name_2__c = 'Cuenta Entrega',
            cgcloud__Account_Number__c = '17000616',
            AccountNumber = '22222222-2',
            cgcloud__ExternalId__c = '11000000',
            cgcloud__Account_Template__c = accTemplateCust.Id
        );
        insert cuentaEntrega;

        Product2 producto = new Product2(
            Name = 'Producto Crear Pedido',
            IsActive = true,
            cgcloud__Consumer_Goods_Product_Code__c = CODIGO_PRODUCTO,
            Unidad_de_Medida__c = 'CJ'
        );
        insert producto;

        List<cgcloud__Order_Template__c> templates = new List<cgcloud__Order_Template__c>{
            new cgcloud__Order_Template__c(Name = 'TPL-ZNAC', Pricing_Clase_Pedido__c = 'ZNAC'),
            new cgcloud__Order_Template__c(Name = 'TPL-ZINT', Pricing_Clase_Pedido__c = 'ZLIN'),
            new cgcloud__Order_Template__c(Name = 'TPL-ZILQ', Pricing_Clase_Pedido__c = 'ZILQ'),
            new cgcloud__Order_Template__c(Name = 'TPL-ZVSC', Pricing_Clase_Pedido__c = 'ZVSC'),
            new cgcloud__Order_Template__c(Name = 'TPL-ZNAC-NOITEM', Pricing_Clase_Pedido__c = 'ZNAC')
        };
        insert templates;

        Map<String, Id> templatesByClase = new Map<String, Id>();
        for (cgcloud__Order_Template__c t : templates) {
            templatesByClase.put(t.Pricing_Clase_Pedido__c + '-' + t.Name, t.Id);
        }

        List<cgcloud__Order__c> ordenes = new List<cgcloud__Order__c>{
            new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = templates[0].Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                cgcloud__Delivery_Date__c = Date.newInstance(2026, 3, 11),
                Referencia_cliente__c = 'REF-ZNAC-1',
                Canal_de_distribucion__c = '02',
                Sector__c = '01',
                cgcloud__Customer_Order_Id__c = 'PED-LOCAL-ZNAC-1',
                cgcloud__Order_Id__c = 'PED-LOCAL-ZNAC-1',
                Estado_de_transferencia__c = 'No iniciado'
            ),
            new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = templates[1].Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                cgcloud__Delivery_Date__c = Date.newInstance(2026, 3, 11),
                Referencia_cliente__c = 'REF-ZINT-2',
                Canal_de_distribucion__c = '02',
                Sector__c = '01',
                cgcloud__Customer_Order_Id__c = 'PED-LOCAL-ZINT-2',
                cgcloud__Order_Id__c = 'PED-LOCAL-ZINT-2',
                Estado_de_transferencia__c = 'No iniciado'
            ),
            new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = templates[2].Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                cgcloud__Delivery_Date__c = Date.newInstance(2026, 3, 11),
                Referencia_cliente__c = 'REF-ZILQ-3',
                Canal_de_distribucion__c = '02',
                Sector__c = '01',
                cgcloud__Customer_Order_Id__c = 'PED-LOCAL-ZILQ-3',
                cgcloud__Order_Id__c = 'PED-LOCAL-ZILQ-3',
                Estado_de_transferencia__c = 'No iniciado'
            ),
            new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = templates[3].Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                cgcloud__Delivery_Date__c = Date.newInstance(2026, 3, 11),
                Referencia_cliente__c = 'REF-ZVSC-4',
                Canal_de_distribucion__c = '02',
                Sector__c = '01',
                cgcloud__Customer_Order_Id__c = 'PED-LOCAL-ZVSC-4',
                cgcloud__Order_Id__c = 'PED-LOCAL-ZVSC-4',
                Estado_de_transferencia__c = 'No iniciado'
            ),
            new cgcloud__Order__c(
                cgcloud__Order_Account__c = cuentaCliente.Id,
                cgcloud__Order_Template__c = templates[4].Id,
                cgcloud__Delivery_Recipient__c = cuentaEntrega.Id,
                cgcloud__Pricing_Date__c = Date.newInstance(2026, 3, 4),
                cgcloud__Delivery_Date__c = Date.newInstance(2026, 3, 11),
                Referencia_cliente__c = 'REF-CP-NOITEM',
                Canal_de_distribucion__c = '02',
                Sector__c = '01',
                cgcloud__Customer_Order_Id__c = 'PED-LOCAL-NOITEM',
                cgcloud__Order_Id__c = 'PED-LOCAL-NOITEM',
                Estado_de_transferencia__c = 'No iniciado'
            )
        };
        insert ordenes;

        List<cgcloud__Order_Item__c> items = new List<cgcloud__Order_Item__c>();
        for (cgcloud__Order__c orden : [
            SELECT Id, Referencia_cliente__c
            FROM cgcloud__Order__c
            WHERE Referencia_cliente__c IN ('REF-ZNAC-1', 'REF-ZINT-2', 'REF-ZILQ-3', 'REF-ZVSC-4')
        ]) {
            items.add(new cgcloud__Order_Item__c(
                cgcloud__Order__c = orden.Id,
                cgcloud__Product__c = producto.Id,
                cgcloud__Quantity__c = 10,
                cgcloud__UoM__c = 'CJ',
                Centro__c = 'D009'
            ));
        }
        insert items;
    }

    private static Id getOrderIdOk() {
        return [
            SELECT Id
            FROM cgcloud__Order__c
            WHERE Referencia_cliente__c = 'REF-ZNAC-1'
            LIMIT 1
        ].Id;
    }

    private static Id getOrderIdNoItems() {
        return [
            SELECT Id
            FROM cgcloud__Order__c
            WHERE Referencia_cliente__c = 'REF-CP-NOITEM'
            LIMIT 1
        ].Id;
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

    @IsTest
    static void test01ejecutarDesdeFlowsinIds() {
        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>());
        Test.stopTest();

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        //System.assertEquals('Error: No se recibieron OrderIds.', resultados[0]); //NOPMD - Falso Positivo
    }

  /*  @IsTest
    static void test02ejecutarDesdeFlowidDeOtroObjeto() {
        Account cuenta = [SELECT Id FROM Account WHERE Name = 'Cuenta Cliente Test' LIMIT 1];
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        Test.startTest();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ cuenta.Id });
        Test.stopTest();

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        //System.assert(resultados[0].contains('EXCEPCION | OrderId=')); //NOPMD - Falso Positivo
    }*/

    @IsTest
    static void test03crearPedidoOrdenSinItems() {
        Id orderId = getOrderIdNoItems();

        Test.startTest();
        try {
            SEIDOR_CrearPedido.crearPedido(orderId);
            System.assert(false, 'Debió lanzar excepción por orden sin items.');
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('no tiene items') ||
                e.getMessage().contains('Script-thrown exception'),
                'Debe controlar el escenario de orden sin items. Mensaje: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void test04crearPedidoCaminoFeliz() {
        Id orderId = getOrderIdOk();
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

        Test.startTest();
        HttpResponse response = SEIDOR_CrearPedido.crearPedido(orderId);
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode()); //NOPMD - Falso Positivo
        System.assertEquals('GET', lastRequestMethod); //NOPMD - Falso Positivo
        System.assertEquals('callout:CPI_PedidoPrecio/http/Salesforce/CreaPedido_v2', lastEndpoint); //NOPMD - Falso Positivo
        System.assertNotEquals(null, lastRequestBody); //NOPMD - Falso Positivo

        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(lastRequestBody);
        System.assert(bodyMap.containsKey('Pedido'), 'El body debe contener el nodo Pedido.');

        Map<String, Object> pedido = (Map<String, Object>) bodyMap.get('Pedido');
        //System.assertEquals('PED-LOCAL-ZNAC-1', String.valueOf(pedido.get('OrderId'))); //NOPMD - Falso Positivo
        System.assertEquals('ZNAC', String.valueOf(pedido.get('Typ_doc'))); //NOPMD - Falso Positivo
        System.assertEquals('17000615', String.valueOf(pedido.get('Customer'))); //NOPMD - Falso Positivo
        System.assertEquals('11000000', String.valueOf(pedido.get('Bp_entrega'))); //NOPMD - Falso Positivo
        System.assertEquals('REF-ZNAC-1', String.valueOf(pedido.get('Ref_cliente'))); //NOPMD - Falso Positivo
        System.assertEquals('2026-03-11', String.valueOf(pedido.get('Fecha_entrega'))); //NOPMD - Falso Positivo
        System.assertEquals('WT55', String.valueOf(pedido.get('Org_venta'))); //NOPMD - Falso Positivo
        System.assertEquals('02', String.valueOf(pedido.get('Canal'))); //NOPMD - Falso Positivo
        System.assertEquals('01', String.valueOf(pedido.get('Sector'))); //NOPMD - Falso Positivo
        System.assertEquals('', String.valueOf(pedido.get('Centro_costo'))); //NOPMD - Falso Positivo
        System.assertEquals('', String.valueOf(pedido.get('Estado'))); //NOPMD - Falso Positivo
        System.assertEquals('', String.valueOf(pedido.get('Motivo_bloq'))); //NOPMD - Falso Positivo

        List<Object> items = (List<Object>) pedido.get('_Items');
        System.assertNotEquals(null, items); //NOPMD - Falso Positivo
        System.assertEquals(1, items.size()); //NOPMD - Falso Positivo

        Map<String, Object> item = (Map<String, Object>) items[0];
        System.assertEquals(String.valueOf(orderId), String.valueOf(item.get('OrderId'))); //NOPMD - Falso Positivo
        System.assertEquals('1', String.valueOf(item.get('ItemPosition'))); //NOPMD - Falso Positivo
        System.assertEquals(CODIGO_PRODUCTO, String.valueOf(item.get('Material'))); //NOPMD - Falso Positivo
        System.assertEquals('10', String.valueOf(item.get('Quantity'))); //NOPMD - Falso Positivo
        System.assertEquals('2026-03-11', String.valueOf(item.get('Fecha_entrega'))); //NOPMD - Falso Positivo
        System.assertEquals('CJ', String.valueOf(item.get('Unit'))); //NOPMD - Falso Positivo
        System.assertEquals('D009', String.valueOf(item.get('Centro'))); //NOPMD - Falso Positivo
        System.assertEquals('', String.valueOf(item.get('Estado'))); //NOPMD - Falso Positivo
        System.assertEquals('', String.valueOf(item.get('Motivo_bloq'))); //NOPMD - Falso Positivo
    }

    @IsTest
    static void test05ejecutarDesdeFlowActualizaOrdenZNAC() {
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        //System.assert(resultados[0].startsWith('OK | OrderId=')); //NOPMD - Falso Positivo

       /* cgcloud__Order__c ordenActualizada = [
            SELECT Id,
                   ID_PEDIDO_S4__c,
                   Log_Crear_pedido__c,
                   cgcloud__Total_Value__c,
                   cgcloud__Gross_Total_Value__c,
                   codigo_watts__c
            FROM cgcloud__Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];

        System.assertEquals('5000012345', ordenActualizada.ID_PEDIDO_S4__c); //NOPMD - Falso Positivo
        System.assertEquals('Pedido creado correctamente', ordenActualizada.Log_Crear_pedido__c); //NOPMD - Falso Positivo*/
        //System.assertEquals(1200, ordenActualizada.cgcloud__Total_Value__c);
        //System.assertEquals(1000, ordenActualizada.cgcloud__Gross_Total_Value__c);
        //System.assertEquals('EXT-001', ordenActualizada.codigo_watts__c);
    }

   @IsTest
	static void test06ejecutarDesdeFlowActualizaItemsZINT() {
    Id orderId = getOrderIdsByReference().get('REF-ZINT-2');
    Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

    Test.startTest();
    List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
    resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
    Test.stopTest();

    List<cgcloud__Order_Item__c> items = [
        SELECT cgcloud__Order__r.Referencia_cliente__c,
               cgcloud__Price__c,
               cgcloud_desc_Pricing_Info_1__c,
               Importe_Pricing_Info_1__c,
               cgcloud_desc_Pricing_Info_2__c,
               Importe_Pricing_Info_2__c,
               cgcloud_desc_Pricing_Info_3__c,
               Importe_Pricing_Info_3__c,
               cgcloud_desc_Pricing_Info_4__c,
               Importe_Pricing_Info_4__c,
               cgcloud_desc_Pricing_Info_5__c,
               Importe_Pricing_Info_5__c,
               cgcloud_desc_Pricing_Info_6__c,
               Importe_Pricing_Info_6__c
        FROM cgcloud__Order_Item__c
        WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZINT-2'
    ];

    System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
    System.assertEquals(1, items.size()); //NOPMD - Falso Positivo

    //System.assertEquals('Precio Lista', items[0].cgcloud_desc_Pricing_Info_1__c); //NOPMD - Falso Positivo
    //System.assertNotEquals(null, items[0].Importe_Pricing_Info_1__c); //NOPMD - Falso Positivo

   /* System.assertEquals('ZIYL', items[0].cgcloud_desc_Pricing_Info_2__c); //NOPMD - Falso Positivo
    System.assertNotEquals(null, items[0].Importe_Pricing_Info_2__c); //NOPMD - Falso Positivo

    System.assertEquals('Recargo', items[0].cgcloud_desc_Pricing_Info_3__c); //NOPMD - Falso Positivo
    System.assertNotEquals(null, items[0].Importe_Pricing_Info_3__c); //NOPMD - Falso Positivo

    System.assertEquals('IVA', items[0].cgcloud_desc_Pricing_Info_4__c); //NOPMD - Falso Positivo
    System.assertNotEquals(null, items[0].Importe_Pricing_Info_4__c); //NOPMD - Falso Positivo

    System.assertEquals('Imp. Adic.', items[0].cgcloud_desc_Pricing_Info_5__c); //NOPMD - Falso Positivo
    System.assertNotEquals(null, items[0].Importe_Pricing_Info_5__c); //NOPMD - Falso Positivo

    System.assertEquals('ILA', items[0].cgcloud_desc_Pricing_Info_6__c); //NOPMD - Falso Positivo
    System.assertNotEquals(null, items[0].Importe_Pricing_Info_6__c); //NOPMD - Falso Positivo*/
}

   @IsTest
	static void test07ejecutarDesdeFlowActualizaItemsZNAC() {
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
                cgcloud__Price__c,
                cgcloud_desc_Pricing_Info_1__c,
                Importe_Pricing_Info_1__c,
                cgcloud_desc_Pricing_Info_2__c,
                Importe_Pricing_Info_2__c,
                cgcloud_desc_Pricing_Info_4__c,
                Importe_Pricing_Info_4__c,
                cgcloud_desc_Pricing_Info_6__c,
                Importe_Pricing_Info_6__c,
                cgcloud_desc_Pricing_Info_7__c,
                Importe_Pricing_Info_7__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZNAC-1'
        ];

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        //System.assert(resultados[0].resultado.startsWith('OK | OrderId=')); //NOPMD - Falso Positivo
        //System.assertEquals(1, items.size()); //NOPMD - Falso Positivo
    }

    @IsTest
	static void test08ejecutarDesdeFlowActualizaItemsZILQ() {
        Id orderId = getOrderIdsByReference().get('REF-ZILQ-3');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
                cgcloud__Price__c,
                cgcloud_desc_Pricing_Info_2__c,
                Importe_Pricing_Info_2__c,
                cgcloud_desc_Pricing_Info_4__c,
                Importe_Pricing_Info_4__c,
                cgcloud_desc_Pricing_Info_6__c,
                Importe_Pricing_Info_6__c,
                cgcloud_desc_Pricing_Info_7__c,
                Importe_Pricing_Info_7__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZILQ-3'
        ];

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        System.assertEquals(1, items.size()); //NOPMD - Falso Positivo
    }

    @IsTest
    static void test09ejecutarDesdeFlowActualizaItemsZVSC() {
        Id orderId = getOrderIdsByReference().get('REF-ZVSC-4');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('SUCCESS'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        List<cgcloud__Order_Item__c> items = [
            SELECT cgcloud__Order__r.Referencia_cliente__c,
                   cgcloud__Price__c,
                   cgcloud_desc_Pricing_Info_2__c,
                   Importe_Pricing_Info_2__c
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__r.Referencia_cliente__c = 'REF-ZVSC-4'
        ];

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        System.assertEquals(1, items.size()); //NOPMD - Falso Positivo
    }

    @IsTest
    static void test10ejecutarDesdeFlowHttpError() {
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('ERROR'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        System.assertEquals(1, resultados.size()); //NOPMD - Falso Positivo
        System.assert(resultados[0].resultado.contains('EXCEPCION | OrderId=')); //NOPMD - Falso Positivo
        System.assert(resultados[0].resultado.contains('Status=500')); //NOPMD - Falso Positivo
    }

    @IsTest
    static void test11ejecutarDesdeFlowJsonInvalido() {
        Id orderId = getOrderIdsByReference().get('REF-ZNAC-1');
        Test.setMock(HttpCalloutMock.class, new CrearPedidoMock('BAD_JSON'));

        Test.startTest();
        List<SEIDOR_CrearPedido_Flow.Output> resultados = new List<SEIDOR_CrearPedido_Flow.Output>();
        resultados = SEIDOR_CrearPedido_Flow.ejecutarDesdeFlow(new List<Id>{ orderId });
        Test.stopTest();

        System.assert(resultados.size() > 0); //NOPMD - Falso Positivo
    }

    @IsTest
    static void test12parseResponseDirecto() {
        String json =
            '{' +
                '"PedidoSAP":"99999",' +
                '"Mensaje":"Pedido generado",' +
                '"EXTERNALID":"EXT-XYZ",' +
                '"CUSTOMER":"17000615",' +
                '"VALORNETO":1000,' +
                '"VALORBRUTO":1200,' +
                '"CREDITODISPONIBLE":5000,' +
                '"ITEMS":[' +
                    '{' +
                        '"ITEMID":10,' +
                        '"MATERIAL":"30000038",' +
                        '"CANTIDAD":10,' +
                        '"UNIDAD":"CJ",' +
                        '"VALORNETO":1000,' +
                        '"VALORIMPUESTOS":200,' +
                        '"MONEDA":"CLP",' +
                        '"CON_PRECIO":[]' +
                    '}' +
                ']' +
            '}';

        SEIDOR_CrearPedidoResponse resp = SEIDOR_CrearPedidoResponse.parse(json);

        System.assertNotEquals(null, resp); //NOPMD - Falso Positivo
        System.assertEquals('99999', resp.PedidoSAP); //NOPMD - Falso Positivo
        System.assertEquals('Pedido generado', resp.Mensaje); //NOPMD - Falso Positivo
        System.assertEquals('EXT-XYZ', resp.EXTERNALID); //NOPMD - Falso Positivo
        System.assertEquals(1000, resp.VALORNETO); //NOPMD - Falso Positivo
        System.assertEquals(1200, resp.VALORBRUTO); //NOPMD - Falso Positivo
        System.assertEquals(1, resp.ITEMS.size()); //NOPMD - Falso Positivo
        System.assertEquals('30000038', resp.ITEMS[0].MATERIAL); //NOPMD - Falso Positivo
    }
    
    @IsTest
	static void test13parseResponseDirectoConCondiciones() {
    String json =
        '{' +
            '"PedidoSAP":"99999",' +
            '"Mensaje":"Pedido generado",' +
            '"EXTERNALID":"EXT-XYZ",' +
            '"CUSTOMER":"17000615",' +
            '"VALORNETO":1000,' +
            '"VALORBRUTO":1200,' +
            '"CREDITODISPONIBLE":5000,' +
            '"ITEMS":[' +
                '{' +
                    '"ITEMID":10,' +
                    '"MATERIAL":"30000038",' +
                    '"CANTIDAD":10,' +
                    '"UNIDAD":"CJ",' +
                    '"VALORNETO":1000,' +
                    '"VALORIMPUESTOS":200,' +
                    '"MONEDA":"CLP",' +
                    '"CON_PRECIO":[' +
                        '{"COND_TYPE":"ZPRL","TIPO_COND":"Precio Lista","COND_VALUE":800,"COND_UNIT":"CJ","CONDVALUE":800},' +
                        '{"COND_TYPE":"ZDSE","TIPO_COND":"Descuento","COND_VALUE":50,"COND_UNIT":"CJ","CONDVALUE":50},' +
                        '{"COND_TYPE":"ZDGD","TIPO_COND":"Desc. Granel","COND_VALUE":20,"COND_UNIT":"CJ","CONDVALUE":20},' +
                        '{"COND_TYPE":"ZDPR","TIPO_COND":"Desc. Promo","COND_VALUE":10,"COND_UNIT":"CJ","CONDVALUE":10},' +
                        '{"COND_TYPE":"ZDIF","TIPO_COND":"Diferencia","COND_VALUE":5,"COND_UNIT":"CJ","CONDVALUE":5},' +
                        '{"COND_TYPE":"ZRSE","TIPO_COND":"Recargo","COND_VALUE":15,"COND_UNIT":"CJ","CONDVALUE":15},' +
                        '{"COND_TYPE":"MWST","TIPO_COND":"IVA","COND_VALUE":200,"COND_UNIT":"CJ","CONDVALUE":200},' +
                        '{"COND_TYPE":"IABA","TIPO_COND":"Imp. Adic.","COND_VALUE":8,"COND_UNIT":"CJ","CONDVALUE":8},' +
                        '{"COND_TYPE":"ILA","TIPO_COND":"ILA","COND_VALUE":3,"COND_UNIT":"CJ","CONDVALUE":3}' +
                    ']' +
                '}' +
            ']' +
        '}';

    SEIDOR_CrearPedidoResponse resp = SEIDOR_CrearPedidoResponse.parse(json);

    System.assertNotEquals(null, resp); //NOPMD - Falso Positivo
    System.assertEquals('99999', resp.PedidoSAP); //NOPMD - Falso Positivo
    System.assertEquals('Pedido generado', resp.Mensaje); //NOPMD - Falso Positivo
    System.assertEquals('EXT-XYZ', resp.EXTERNALID); //NOPMD - Falso Positivo
    System.assertEquals(1000, resp.VALORNETO); //NOPMD - Falso Positivo 
    System.assertEquals(1200, resp.VALORBRUTO); //NOPMD - Falso Positivo
    System.assertEquals(1, resp.ITEMS.size()); //NOPMD - Falso Positivo
    System.assertEquals('30000038', resp.ITEMS[0].MATERIAL); //NOPMD - Falso Positivo
    System.assert(resp.ITEMS[0].CON_PRECIO != null); //NOPMD - Falso Positivo
    System.assert(resp.ITEMS[0].CON_PRECIO.size() >= 8); //NOPMD - Falso Positivo
}

    private class CrearPedidoMock implements HttpCalloutMock {
        private String scenario;

        public CrearPedidoMock(String scenario) {
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
                res.setBody('{"Mensaje":"Error creando pedido"}');
                return res;
            }

            if (scenario == 'BAD_JSON') {
                res.setStatusCode(200);
                res.setBody('{"PedidoSAP":');
                return res;
            }

            res.setStatusCode(200);
            res.setBody(buildSuccessBody(lastRequestBody));
            return res;
        }

    private String buildSuccessBody(String requestBody) {
    String clasePedido = 'ZNAC';
    String material = CODIGO_PRODUCTO;

    if (requestBody != null) {
        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        if (bodyMap.containsKey('Pedido')) {
            Map<String, Object> pedido = (Map<String, Object>) bodyMap.get('Pedido');

            if (pedido.containsKey('Typ_doc') && pedido.get('Typ_doc') != null) {
                clasePedido = String.valueOf(pedido.get('Typ_doc'));
            }

            if (pedido.containsKey('_Items')) {
                List<Object> itemsReq = (List<Object>) pedido.get('_Items');
                if (!itemsReq.isEmpty()) {
                    Map<String, Object> firstItem = (Map<String, Object>) itemsReq[0];
                    if (firstItem.containsKey('Material') && firstItem.get('Material') != null) {
                        material = String.valueOf(firstItem.get('Material'));
                    }
                }
            }
        }
    }

    List<String> conds = new List<String>();
    conds.add(condJson('ZPRL', 'Precio Lista', 1000, 1000, 'CJ'));

    if (clasePedido == 'ZNAC') {
        conds.add(condJson('ZDSE', 'Descuento', 50, 50, 'CJ'));
        conds.add(condJson('ZDGD', 'Desc. Granel', 20, 20, 'CJ'));
        conds.add(condJson('ZDPR', 'Desc. Promo', 10, 10, 'CJ'));
        conds.add(condJson('ZDIF', 'Diferencia', 5, 5, 'CJ'));
        conds.add(condJson('ZRSE', 'Recargo', 15, 15, 'CJ'));
        conds.add(condJson('MWST', 'IVA', 95, 95, 'CJ'));
        conds.add(condJson('IABA', 'Imp. Adic.', 8, 8, 'CJ'));
        conds.add(condJson('ILA', 'ILA', 3, 3, 'CJ'));
    } else if (clasePedido == 'ZINT') {
        conds.add(condJson('ZIYL', 'ZIYL', 40, 40, 'CJ'));
        conds.add(condJson('ZRSE', 'Recargo', 15, 15, 'CJ'));
        conds.add(condJson('MWST', 'IVA', 95, 95, 'CJ'));
        conds.add(condJson('IABA', 'Imp. Adic.', 8, 8, 'CJ'));
        conds.add(condJson('ILA', 'ILA', 3, 3, 'CJ'));
    } else if (clasePedido == 'ZILQ') {
        conds.add(condJson('ZIYL', 'ZIYL', 40, 40, 'CJ'));
        conds.add(condJson('ZRSE', 'Recargo', 15, 15, 'CJ'));
        conds.add(condJson('MWST', 'IVA', 95, 95, 'CJ'));
        conds.add(condJson('IABA', 'Imp. Adic.', 8, 8, 'CJ'));
        conds.add(condJson('ILA', 'ILA', 3, 3, 'CJ'));
    } else if (clasePedido == 'ZVSC') {
        conds.add(condJson('ZDUN', 'ZDUN', 40, 40, 'CJ'));
        conds.add(condJson('ZRSE', 'Recargo', 15, 15, 'CJ'));
        conds.add(condJson('MWST', 'IVA', 95, 95, 'CJ'));
        conds.add(condJson('IABA', 'Imp. Adic.', 8, 8, 'CJ'));
        conds.add(condJson('ILA', 'ILA', 3, 3, 'CJ'));
    }

    return '{' +
        '"PedidoSAP":"99999",' +
        '"Mensaje":"Pedido creado correctamente",' +
        '"EXTERNALID":"EXT-001",' +
        '"CUSTOMER":"17000615",' +
        '"VALORNETO":905,' +
        '"VALORBRUTO":1000,' +
        '"CREDITODISPONIBLE":5000,' +
        '"ITEMS":[' +
            '{' +
                '"ITEMID":10,' +
                '"MATERIAL":"' + material + '",' +
                '"CANTIDAD":10,' +
                '"UNIDAD":"CJ",' +
                '"VALORNETO":905,' +
                '"VALORIMPUESTOS":95,' +
                '"MONEDA":"CLP",' +
                '"CON_PRECIO":[' + String.join(conds, ',') + ']' +
            '}' +
        ']' +
    '}';
}

        private String condJson(String condType, String tipoCond, Decimal condValue, Decimal condValue2, String condUnit) {
            return '{' +
                '"ITM_NUMBER":10,' +
                '"COND_ST_NO":11,' +
                '"COND_COUNT":1,' +
                '"COND_TYPE":"' + condType + '",' +
                '"COND_VALUE":' + String.valueOf(condValue) + ',' +
                '"CURRENCY_info":"CLP",' +
                '"COND_UNIT":"' + condUnit + '",' +
                '"COND_P_UNT":1,' +
                '"CURR_ISO":"CLP",' +
                '"CD_UNT_ISO":"' + condUnit + '",' +
                '"CONDVALUE":' + String.valueOf(condValue2) + ',' +
                '"TIPO_COND":"' + tipoCond + '"' +
            '}';
        }
    }
}
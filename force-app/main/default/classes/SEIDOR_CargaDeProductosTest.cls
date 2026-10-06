/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase test para realizar el proceso de test de la carga masiva de productos desde UI y archivo .csv
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 30-01-2026           BB                     Creación de la Clase test.    
***********************************************************************************/
@IsTest
public class SEIDOR_CargaDeProductosTest {


    private static Product2 crearProducto(String codigo) {
        Product2 p = new Product2(
            Name = 'Prod ' + codigo,
            cgcloud__Consumer_Goods_Product_Code__c = codigo
        );
        insert p;
        return p;
    }

    private static Id asegurarOrderTemplate() {
        List<SObject> existentes = Database.query(
             'SELECT Id FROM cgcloud__Order_Template__c LIMIT 1'
        );
        if (!existentes.isEmpty()) {
            return (Id) existentes[0].get('Id'); 
        }
        
        SObject t = Schema.getGlobalDescribe()
            .get('cgcloud__Order_Template__c')
            .newSObject();
        
		Map<String, Schema.SObjectField> fMap =
            Schema.getGlobalDescribe()
                .get('cgcloud__Order_Template__c')
                .getDescribe().fields.getMap();

        if (fMap.containsKey('Name') && fMap.get('Name').getDescribe().isCreateable()) {
            t.put('Name', 'Template Test');
        }
        t.put('Pricing_Clase_Pedido__c', 'ZNAC');
        

        insert t;
        return (Id) t.get('Id');
    }

    private static cgcloud__Order__c crearOrden() {
        Id templateId = asegurarOrderTemplate();
        System.assertNotEquals(null, templateId, 'No se pudo crear/obtener cgcloud__Order_Template__c'); //NOPMD

        cgcloud__Order__c o = new cgcloud__Order__c();
        o.put('cgcloud__Order_Template__c', templateId);

        insert o;
        return o;
    }

       private static Id crearPlantillaOrderItem() {
        cgcloud__Order_Item_Template__c t = new cgcloud__Order_Item_Template__c();
        try { 
            t.Name = 'Item Template'; 
        } catch (Exception e) {
            System.assert(false, 'No se esperaba excepción: ' + e.getMessage()); //NOPMD
        }
        insert t;
        return t.Id;
    }


    private static Map<String, Object> filaController(
        Id orderId,
        String plantillaId,
        String prodCodigoOId,
        Object qty
    ) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('cgcloud__Order__c', String.valueOf(orderId));
        m.put('cgcloud__Order_Item_Template__c', plantillaId);
        m.put('cgcloud__Product__c', prodCodigoOId);
        m.put('cgcloud__Quantity__c', qty);
        return m;
    }


    private static String plantillaPermitidaDesdeCMDT() {
    Plantillas_Permitidas__mdt cfg =
        Plantillas_Permitidas__mdt.getInstance('Plantilla_Standard');

    System.assertNotEquals(
        null,
        cfg,
        'Falta el registro CMDT Plantillas_Permitidas__mdt con DeveloperName = Plantilla_Standard'
    );  //NOPMD
    System.assertEquals(
        true,
        String.isNotBlank(cfg.Id_Order_Item_Template__c),
        'El CMDT Plantilla_Standard debe tener valor en Id_Order_Item_Template__c'
    ); //NOPMD

    return cfg.Id_Order_Item_Template__c;
}


    @IsTest
    static void testEnqueueNullYVacio() {
        SEIDOR_CargaDeProductos.ResultadoEncolado r1 = SEIDOR_CargaDeProductos.enqueueCreateItems(null);
        System.assertEquals(0, r1.totalFilas, 'Validar valor esperado');  //NOPMD

        SEIDOR_CargaDeProductos.ResultadoEncolado r2 = SEIDOR_CargaDeProductos.enqueueCreateItems(new List<Map<String,Object>>());
        System.assertEquals(0, r2.totalFilas, 'Validar valor esperado'); //NOPMD
    }

    @IsTest
    static void testEnqueuePlantillaInvalidaLanzaError() {
        cgcloud__Order__c o = crearOrden();

        List<Map<String,Object>> rows = new List<Map<String,Object>>();
        rows.add(filaController(
            o.Id,
            'a2EO000000INVALIDA', 
            '100',
            '1'
        ));

        Boolean lanzo = false;
        try {
            SEIDOR_CargaDeProductos.enqueueCreateItems(rows);
        } catch (AuraHandledException ex) {
            lanzo = true;
        }
        System.assertEquals(true, lanzo, 'Debió lanzar AuraHandledException por plantilla inválida'); //NOPMD
    }

        @IsTest 
    static void testEnqueueCodigoProductoNoExisteLanzaError() {
        cgcloud__Order__c o = crearOrden();

        String plantillaPermitida = plantillaPermitidaDesdeCMDT();

        List<Map<String,Object>> rows = new List<Map<String,Object>>();
        rows.add(filaController(
        o.Id,
        plantillaPermitida,
        '200',  
        '1'     
        ));

        Boolean lanzo = false;
        try {
            SEIDOR_CargaDeProductos.enqueueCreateItems(rows);
        } catch (AuraHandledException ex) {
            lanzo = true;
        }
        System.assertEquals(true, lanzo, 'Debió lanzar AuraHandledException por código de producto inexistente'); //NOPMD
    }


    @IsTest
    static void testEnqueueOkEncolaJob() {
        cgcloud__Order__c o = crearOrden();
        crearProducto('100');

        String plantillaPermitida = plantillaPermitidaDesdeCMDT();

        List<Map<String,Object>> rows = new List<Map<String,Object>>();
        rows.add(filaController(
            o.Id,
            plantillaPermitida,  
            '100',
            '2'
        ));

        Test.startTest();
        SEIDOR_CargaDeProductos.ResultadoEncolado res =
            SEIDOR_CargaDeProductos.enqueueCreateItems(rows);
        Test.stopTest();

        System.assertNotEquals(null, res.jobId);  //NOPMD
        System.assertEquals(1, res.totalFilas, 'Validar valor esperado');  //NOPMD
    }

    @IsTest
    static void testQueueableInsertaItems() {
        cgcloud__Order__c o = crearOrden();
        Product2 p = crearProducto('A1');
        Id plantillaItem = crearPlantillaOrderItem();

        SEIDOR_CargaDeProductos_Queueable.FilaInput f =
            new SEIDOR_CargaDeProductos_Queueable.FilaInput();
        f.idOrden = o.Id;
        f.idProducto = p.Id;
        f.idPlantillaItem = plantillaItem;
        f.cantidad = 2;

        List<SEIDOR_CargaDeProductos_Queueable.FilaInput> filas =
            new List<SEIDOR_CargaDeProductos_Queueable.FilaInput>{ f };

        Test.startTest();
        System.enqueueJob(new SEIDOR_CargaDeProductos_Queueable(filas, 0, 50));
        Test.stopTest();

        List<cgcloud__Order_Item__c> items = [
            SELECT Id
            FROM cgcloud__Order_Item__c
            WHERE cgcloud__Order__c = :o.Id
        ];
        System.assertEquals(1, items.size( ), 'Validar valor esperado'); //NOPMD
    }

    @IsTest
    static void testEsSalesforceId() {
        
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
            
            Account acc = new Account();
            acc.Name = 'Summer test account';
            acc.cgcloud__Name_2__c = 'Summer test';
            acc.cgcloud__Account_Number__c = 'Summer account Number';
            acc.cgcloud__Account_Template__c = accTemplateCust.Id;
            insert acc;
        // Crear un registro real para obtener un Id válido
        //Account acc = new Account(Name = 'Test');
        //insert acc;

        String id18 = String.valueOf(acc.Id);
        String id15 = id18.substring(0, 15);

        System.assertEquals(true, SEIDOR_CargaDeProductos_Queueable.esSalesforceId(id15)); //NOPMD - Falso Positivo

        System.assertEquals(true, SEIDOR_CargaDeProductos_Queueable.esSalesforceId(id18)); //NOPMD - Falso Positivo

        System.assertEquals(false, SEIDOR_CargaDeProductos_Queueable.esSalesforceId('NO_ES_ID')); //NOPMD - Falso Positivo

        System.assertEquals(false, SEIDOR_CargaDeProductos_Queueable.esSalesforceId(null)); //NOPMD - Falso Positivo
    }
}
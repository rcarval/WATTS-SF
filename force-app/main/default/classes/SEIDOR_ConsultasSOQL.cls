/*
    Clase apex : Consultas SOQL y Operaciones DML
    Test: SEIDOR_ServicioCasosComentarioTest
*/
public class SEIDOR_ConsultasSOQL {
    /**
     * metodo para crear casos
     */
    public static Case insertCaso(Case caso){
        if(Schema.SObjectType.Case.isCreateable()){
            System.debug(caso);
            insert caso; //NOPMD - ApexCRUDViolation
            return caso;
        }else{
            System.debug('Usuario no tiene permisos para crear casos');
            return null;
        }
    }

    /**
     * metodo para crear contactos en la cuenta consumidor
     */
    public static Contact crearContactoConsumidor(String rut, String nombre, String apellidos, String email, String celular){
        try{
            Account_Consumidores__mdt metadato = Account_Consumidores__mdt.getInstance('Cuenta_Cosumidores');

            if(Schema.SObjectType.Contact.isCreateable()){
                Contact contacto = new Contact(
                    firstName = nombre,
                    lastName = apellidos,
                    email = email,
                    phone = celular,
                    Rut_Consumidor__c = rut,
                    AccountId = metadato.Id_Cuenta_Consumidores__c
                );

                insert contacto;//NOPMD
                return contacto;
            } else {
                System.debug('Usuario no tiene permisos para crear Contactos');
            }
        } catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return null;
    }

    /**
     * metodo para buscar contactos de la cuenta consumidor
     */
    public static Contact buscarContactoConsumidor(String rut){
        try{
            if(!Schema.SObjectType.Contact.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Contactos');
                return null;
            }
            List <Contact> contacto = [SELECT Id //NOPMD - Falso Positivo
                                       FROM Contact
                                       WHERE Rut_Consumidor__c =: rut
                                       //AND AccountId =: metadato.Id_Cuenta_Consumidores__c
                                       LIMIT 1 ];

            if (contacto.isEmpty()) {
                return null;
            } else {
                return contacto[0];
            }

        } catch (Exception e){
            System.debug('Error en obtener datos'+e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return null;
    }

    /**
     * metodo para buscar cuenta
     */
    public static Account buscarCuenta(String rut){
        try{
            if(!Schema.SObjectType.Account.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Cuentas');
                return null;
            }
            List <Account> cuenta = [SELECT Id //NOPMD - Falso Positivo
                                       FROM Account
                                       WHERE AccountNumber =: rut
                                       LIMIT 1 ];

            if (cuenta.isEmpty()) {
                return null;
            } else {
                return cuenta[0];
            }

        } catch (Exception e){
            System.debug('Error en obtener datos'+e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return null;
    }


    /**
     * metodo para adjuntar archivo a Caso
     */
    public static Boolean createContentDocument(String base64String, String fileName, Id idCaso) {
        if(!Schema.SObjectType.ContentVersion.isAccessible() ||
           !Schema.SObjectType.ContentVersion.isCreateable() ||
           !Schema.SObjectType.ContentDocumentLink.isAccessible() ||
           !Schema.SObjectType.ContentDocumentLink.isCreateable()){
            System.debug('Usuario no tiene permisos para crear Archivos');
            return false;
        }
        Blob fileBlob = EncodingUtil.base64Decode(base64String);

        // 2. crear registro de  ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = fileBlob;
        cv.ContentLocation = 'S'; // 'S' for Salesforce document, 'E' for external

        try {
            insert cv; //NOPMD

            // 3. Query para obtener el contentDocumentId del archivo creado
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            // 4. Se crea registro en contentDocumentLink para relacionar archivo al caso
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = idCaso;
            cdl.Visibility = 'AllUsers';

            insert cdl;//NOPMD

            System.debug('Archivo creado correctamente. ContentDocumentId: ' + contentDocumentId);
			return true;
        } catch (DmlException e) {
            System.debug('Error creating or linking file: ' + e.getMessage());
            return false;
        }
    }

    /**
     * metodo para buscar producto
     */
    public static Product2 buscarProducto(String codigoBarra) {
        try{
            if(!Schema.SObjectType.Product2.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Productos');
                return null;
            }
            List <Product2> producto = [SELECT Id, Name //NOPMD - Falso Positivo
                                       FROM Product2
                                       WHERE cgcloud__GTIN__c =: codigoBarra
                                       LIMIT 1 ];

            if (producto.isEmpty()) {
                return null;
            } else {
                return producto[0];
            }

        } catch (Exception e){
            System.debug('Error en obtener datos'+e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return null;

    }
    
    /************ Metodo para buscar metadato personalizado de producto por defecto ******************/
    public static Product2 buscarProductoXDefecto(){
        try{
            Producto_Por_Defecto__mdt metadato = Producto_Por_Defecto__mdt.getInstance('Producto_Mal_Informado');
            if(!Schema.SObjectType.Product2.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Productos');
                return null;
            }
            Product2 producto = [SELECT Id, Name //NOPMD - Falso Positivo
                                       FROM Product2
                                       WHERE Id =: metadato.ID_Producto__c];

            return producto;
        } catch (Exception e){
            System.debug('Error en obtener datos'+e.getMessage());
            System.debug(e.getStackTraceString());
        }
        return null;
        
    }

    /********************** SIMULACION **************/
    public static cgcloud__Order__c obtenerOrden(Id orderId){
        try{
            if(!Schema.SObjectType.cgcloud__Order__c.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Ordenes');
                return null;
            }
            cgcloud__Order__c ord = [SELECT Id, codigo_watts__c, cgcloud__Customer_Order_Id__c, cgcloud__Order_Id__c, //NOPMD - ApexCRUDViolation
                                           		cgcloud__Order_Account__r.cgcloud__Account_Number__c, cgcloud__Order_Account__r.Centro_Suministrador__c,
                                                cgcloud__Pricing_Date__c,cgcloud__Order_Template__r.Pricing_Clase_Pedido__c,
                                                cgcloud__Delivery_Recipient__r.cgcloud__ExternalId__c,Centro__c, Mensaje_SAP__c,
                                     			Referencia_cliente__c, cgcloud__Delivery_Date__c, Organizacion_de_ventas__c, Canal_de_distribucion__c,
                                     			Sector__c, cgcloud__Gross_Total_Value__c, cgcloud__Total_Value__c, cgcloud__Order_Account__c
                                 FROM cgcloud__Order__c
                                 WHERE Id = :orderId ];
            return ord;
        } catch(Exception e){
            return null;
        }
    }

    public static List<cgcloud__Order_Item__c> obtenerOrdenItems(Id orderId){
        try{
            if(!Schema.SObjectType.cgcloud__Order_Item__c.isAccessible()) {
                System.debug('Usuario no tiene permisos para consultar Productos de Ordenes');
                return null;
            }
            List<cgcloud__Order_Item__c> listOrdItems = [SELECT cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c,//NOPMD - Falso Positivo
                                                                cgcloud__Quantity__c, cgcloud__UoM__c, Fecha_de_entrega__c, Centro__c,
                                                                cgcloud_desc_Pricing_Info_1__c, Importe_Pricing_Info_1__c, cgcloud__Pricing_Info_1__c,
                                                                cgcloud_desc_Pricing_Info_2__c, Importe_Pricing_Info_2__c, cgcloud__Pricing_Info_2__c,
                                                                cgcloud_desc_Pricing_Info_3__c, Importe_Pricing_Info_3__c, cgcloud__Pricing_Info_3__c,
                                                                cgcloud_desc_Pricing_Info_4__c, Importe_Pricing_Info_4__c, cgcloud__Pricing_Info_4__c,
                                                                cgcloud_desc_Pricing_Info_5__c, Importe_Pricing_Info_5__c, cgcloud__Pricing_Info_5__c,
                                                                cgcloud_desc_Pricing_Info_6__c, Importe_Pricing_Info_6__c, cgcloud__Pricing_Info_6__c,
                                                                cgcloud_desc_Pricing_Info_7__c, Importe_Pricing_Info_7__c, cgcloud__Pricing_Info_7__c,
                                                                cgcloud_desc_Pricing_Info_8__c, Importe_Pricing_Info_8__c, cgcloud__Pricing_Info_8__c,
                                                                cgcloud_desc_Pricing_Info_9__c, Importe_Pricing_Info_9__c, cgcloud__Pricing_Info_9__c,
                                                                cgcloud_desc_Pricing_Info_10__c, Importe_Pricing_Info_10__c, cgcloud__Pricing_Info_10__c,
                                                         		cgcloud__Product__r.Unidad_de_Medida__c
                                                        FROM cgcloud__Order_Item__c
                                                        WHERE cgcloud__Order__c = :orderId ];
           if (listOrdItems.isEmpty()) {
                return null;
            } else {
                return listOrdItems;
            }
        } catch(Exception e){
            return null;
        }
    }
    
    
}
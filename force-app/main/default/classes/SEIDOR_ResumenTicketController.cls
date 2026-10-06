/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: clase apex de Controlador para la visualforce para generar el resumen del Ticket Caso y
cargar la lista dinámica de productos del objeto Producto_Centrales__c.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 18-02-2026           BB                     Creación de la Clase.
1.1 06-05-2026           Seidor                 Adjuntar el PDF generado a la
                                                lista de Archivos del Case.
***********************************************************************************/
public with sharing class SEIDOR_ResumenTicketController {

    @TestVisible
    private static final String GUARD_PARAM   = 'attached';
    @TestVisible
    private static final String GUARD_VALUE   = 'true';
    @TestVisible
    private static final String DEFAULT_PAGE  = 'ResumenTicket';

    public Case caso { get; private set; }


    public List<Producto_Centrales__c> productosCentral { get; private set; }

    public SEIDOR_ResumenTicketController(ApexPages.StandardController controller) {
        Id caseId = (Id) controller.getId();

        productosCentral = new List<Producto_Centrales__c>();

        if (caseId == null) {
            return;
        }

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new SecurityException('No tienes permisos para acceder a Case.');
        }


        List<Case> casos = [
            SELECT Id, CaseNumber, Contact.Name, Contact.MailingStreet, Contact.MailingCity, Contact.MailingCountry,
                   Contact.Phone, Description, TIPO__c, Owner.Name, Subject, Origin, Status, IsEscalated, Priority,
                   CATEGORIA_DE_SERVICIO__c, MOTIVO__c, SUBMOTIVO__c, ClosedDate, CreatedDate,
                   Product.cgcloud__Consumer_Goods_Product_Code__c, Product.Name,
                   CANTIDAD_RECLAMADA_POR_CONSUMIDOR__c, CANTIDAD_A_REPONER_POR_WATT_S__c, FECHA_DE_VENCIMIENTO__c,
                   CANTIDAD_RETIRADA__c, LOTE__c, 	Nombre_Chofer__c, Codigo_del_transporte__c,
                   Account.Name, Codigo_del_cliente__c, Account.ShippingStreet, Account.ShippingCity, Account.ShippingCountry,Account.BillingStreet, Account.BillingCity, Account.BillingCountry,
                   Account.cgcloud__Name_2__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        casos = (List<Case>) Security.stripInaccessible(AccessType.READABLE, casos).getRecords();
        caso = (casos.isEmpty()) ? null : casos[0];

        if (!Schema.sObjectType.Producto_Centrales__c.isAccessible()) {
            throw new SecurityException('No tienes permisos para acceder a Producto_Centrales__c.');
        }

        // SOQL productos
        List<Producto_Centrales__c> tmpProductos = [
            SELECT Id,
                   Descripcion_del_producto__c,
                   CODIGO__c,
                   MOTIVO__c,
                   CANTIDAD_RECLAMADA__c,
                   CANTIDAD_RETIRADA__c,
                   UNIDAD_DE_MEDIDA__c,
                   Case__c
            FROM Producto_Centrales__c
            WHERE Case__c = :caseId
            ORDER BY CreatedDate ASC
        ];

        tmpProductos = (List<Producto_Centrales__c>) Security.stripInaccessible(AccessType.READABLE, tmpProductos).getRecords();
        productosCentral = tmpProductos;
    }

    public Boolean getTieneProductosCentral() {
        return productosCentral != null && !productosCentral.isEmpty();
    }

    /**
     * Acción invocada por el atributo `action` de las páginas Visualforce
     * (SEIDOR_ResumenTicketCliente, SEIDOR_ResumenTicketClienteProductos,
     * SEIDOR_ResumenTicketConsumidor) para que, además de mostrar el PDF
     * al usuario, una copia del mismo quede guardada como Archivo en la
     * lista relacionada estándar del Case.
     *
     * Estrategia:
     *  - Para obtener el PDF se invoca getContentAsPDF() sobre la propia
     *    página, lo que provoca un re-render interno. Para evitar la
     *    recursión infinita se usa el parámetro de URL GUARD_PARAM. Cuando
     *    la página se renderiza con ese parámetro ya en true, el método
     *    retorna inmediatamente y la página simplemente se pinta como PDF.
     *  - getContentAsPDF() debe ejecutarse antes de cualquier DML
     *    (restricción de Salesforce: "uncommitted work pending"), por eso
     *    primero se obtiene el Blob y luego se delega el guardado en
     *    SEIDOR_PdfFileService.
     *  - Cualquier excepción al guardar se atrapa para no romper la
     *    visualización del PDF al usuario.
     */
    public PageReference savePdfToCase() {
        PageReference current = ApexPages.currentPage();

        if (current != null && GUARD_VALUE.equals(current.getParameters().get(GUARD_PARAM))) {
            return null;
        }

        if (caso == null || caso.Id == null) {
            return null;
        }

        try {
            PageReference pdfPage = clonePageWithGuard(current);

            Blob pdfBody = Test.isRunningTest()
                ? Blob.valueOf('TEST_PDF_BODY')
                : pdfPage.getContentAsPDF();

            SEIDOR_PdfFileService.attachPdfToRecord(
                caso.Id,
                pdfBody,
                buildFileName(current)
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'SEIDOR_ResumenTicketController.savePdfToCase error: '
                + e.getMessage() + '\n' + e.getStackTraceString());
        }

        return null;
    }

    @TestVisible
    private static PageReference clonePageWithGuard(PageReference current) {
        String url = (current != null && current.getUrl() != null) ? current.getUrl() : '/apex/' + DEFAULT_PAGE;
        Integer q = url.indexOf('?');
        String basePath = (q >= 0) ? url.substring(0, q) : url;

        PageReference cloned = new PageReference(basePath);
        if (current != null) {
            Map<String, String> params = current.getParameters();
            if (params != null && !params.isEmpty()) {
                cloned.getParameters().putAll(params);
            }
        }
        cloned.getParameters().put(GUARD_PARAM, GUARD_VALUE);
        return cloned;
    }

    @TestVisible
    private String buildFileName(PageReference current) {
        String pageName = extractPageName(current != null ? current.getUrl() : null);
        String caseRef  = (caso != null && String.isNotBlank(caso.CaseNumber)) ? caso.CaseNumber : '';
        String stamp    = DateTime.now().format('yyyyMMdd_HHmmss');
        return String.isBlank(caseRef) ? pageName + '_' + stamp : pageName + '_' + caseRef + '_' + stamp;
    }

    @TestVisible
    private static String extractPageName(String url) {
        if (String.isBlank(url)) {
            return DEFAULT_PAGE;
        }
        String trimmed = url.startsWith('/apex/') ? url.substring(6) : url;
        Integer q = trimmed.indexOf('?');
        if (q >= 0) {
            trimmed = trimmed.substring(0, q);
        }
        return String.isBlank(trimmed) ? DEFAULT_PAGE : trimmed;
    }
}
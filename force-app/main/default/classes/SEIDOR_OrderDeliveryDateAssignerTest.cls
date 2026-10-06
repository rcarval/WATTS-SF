/**********************************************************************************
Desarrollado por: Seidor
Proyecto: Watts
Descripción: Pruebas unitarias para SEIDOR_OrderDeliveryDateAssigner.
---------------------------------------------------------------------------------
No.   Fecha           Autor                          Descripción
----- --------------- ------------------------------ ----------------------------
1.0   10-05-2026      Seidor                         Creación de la clase test.
1.1   14-05-2026      Seidor                         Datos comunes (Account
                                                     Template y Org Unit) se
                                                     insertan una sola vez en
                                                     @TestSetup. buildAccount
                                                     reutiliza esos registros y
                                                     solo varía el Name.
***********************************************************************************/
@IsTest
public class SEIDOR_OrderDeliveryDateAssignerTest {

    private static final String DEFAULT_TZ   = 'America/Santiago';
    private static final String SALES_ORG    = '0001';
    private static final String TEMPLATE_NAME = 'Customer';
    private static final String ORDER_TEMPLATE_NAME = 'Advertising Material';

    private static final List<String> DAY_NAMES = new List<String>{
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    };

    // Cache por test method para evitar SOQL repetida al crear varias Accounts
    private static Id cachedAdminUserId;
    private static Id cachedAccountTemplateId;
    private static Id cachedOrderTemplateId;

    /**
     * Se ejecuta UNA sola vez por clase de test. Inserta los datos comunes
     * (Account Template y Org Unit) que necesitan todos los Accounts creados
     * más adelante para superar las validaciones del paquete cgcloud:
     *   - El flow "Account After Save - Asignar registros CGC por defecto" busca
     *     un cgcloud__Org_Unit__c cuyo Name coincida con el OwnerId de la cuenta.
     *   - La cuenta requiere un cgcloud__Account_Template__c válido.
     */
    @TestSetup
    static void prepararDatosComunes() {
        User adminUser = obtenerUsuarioAdmin();

        insert new cgcloud__Account_Template__c(
            Name                   = TEMPLATE_NAME,
            cgcloud__Sales_Org__c  = SALES_ORG
        );

        insert new cgcloud__Order_Template__c(
            Name = ORDER_TEMPLATE_NAME,
            cgcloud__Valid_From__c = Date.newInstance(2000, 1, 1),
            cgcloud__Valid_Thru__c = Date.newInstance(2099, 12, 31),
            cgcloud__Document_Type__c = 'OrderEntry',
            cgcloud__Sales_Org__c = SALES_ORG,
            Pricing_Clase_Pedido__c = 'ZNAC',
            cgcloud__Creation_Platform__c = 'Both'
        );

        insert new cgcloud__Org_Unit__c(
            Name                   = adminUser.Id,
            cgcloud__Sales_Org__c  = SALES_ORG,
            cgcloud__Org_Level__c  = 'SalesRep',
            cgcloud__Org_Type__c   = 'Sales'
        );
    }

    private static User obtenerUsuarioAdmin() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name IN ('System Administrator', 'Administrador del sistema')
              AND IsActive = true
            LIMIT 1
        ];
    }

    private static Id getAdminUserId() {
        if (cachedAdminUserId == null) {
            cachedAdminUserId = obtenerUsuarioAdmin().Id;
        }
        return cachedAdminUserId;
    }

    private static Id getAccountTemplateId() {
        if (cachedAccountTemplateId == null) {
            cachedAccountTemplateId = [
                SELECT Id
                FROM cgcloud__Account_Template__c
                WHERE Name = :TEMPLATE_NAME
                LIMIT 1
            ].Id;
        }
        return cachedAccountTemplateId;
    }

    private static Id getOrderTemplateId() {
        if (cachedOrderTemplateId == null) {
            cachedOrderTemplateId = [
                SELECT Id
                FROM cgcloud__Order_Template__c
                WHERE Name = :ORDER_TEMPLATE_NAME
                LIMIT 1
            ].Id;
        }
        return cachedOrderTemplateId;
    }

    private static OperatingHours buildOperatingHours(String name) {
        OperatingHours oh = new OperatingHours(Name = name, TimeZone = DEFAULT_TZ);
        insert oh;
        return oh;
    }

    private static void buildTimeSlots(Id operatingHoursId, List<String> days) {
        List<TimeSlot> slots = new List<TimeSlot>();
        for (String day : days) {
            slots.add(new TimeSlot(
                OperatingHoursId = operatingHoursId,
                DayOfWeek        = day,
                StartTime        = Time.newInstance(8, 0, 0, 0),
                EndTime          = Time.newInstance(17, 0, 0, 0),
                Type             = 'Normal'
            ));
        }
        if (!slots.isEmpty()) {
            insert slots;
        }
    }

    /**
     * Crea una nueva Account reutilizando el Account Template y el Org Unit
     * ya insertados en @TestSetup. Lo único que varía por llamada es el Name
     * (y opcionalmente el OperatingHoursId).
     */
    private static Account buildAccount(String name, Id operatingHoursId) {
        Account a = new Account(
            Name                          = name,
            OwnerId                       = getAdminUserId(),
            cgcloud__Account_Template__c  = getAccountTemplateId()
        );
        if (operatingHoursId != null) {
            a.put('OperatingHoursId', operatingHoursId);
        }
        insert a;
        return a;
    }

    private static cgcloud__Order__c buildOrder(Id accountId) {
        cgcloud__Order__c o = new cgcloud__Order__c();
        if (accountId != null) {
            o.cgcloud__Order_Account__c = accountId;
            o.cgcloud__Order_Template__c = getOrderTemplateId();
        }
        insert o;
        return o;
    }

    /** Nombre del día actual en inglés, calculado igual que la clase bajo prueba. */
    private static String todayDayName() {
        Date today = Date.today();
        Integer idx = SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(today);
        return DAY_NAMES[idx];
    }

    /** Devuelve la fecha esperada del próximo día indicado, excluyendo hoy. */
    private static Date expectedNextDate(String dayName) {
        Date today = Date.today();
        Integer todayIdx = SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(today);
        Integer targetIdx = DAY_NAMES.indexOf(dayName);
        Integer diff = Math.mod(targetIdx - todayIdx + 7, 7);
        if (diff == 0) {
            diff = 7;
        }
        return today.addDays(diff);
    }

    @IsTest
    static void dayIndexOf_devuelveIndiceCorrecto() {
        System.assertEquals(0, SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(Date.newInstance(2024, 1, 1)), 'Lunes esperado');
        System.assertEquals(1, SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(Date.newInstance(2024, 1, 2)), 'Martes esperado');
        System.assertEquals(6, SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(Date.newInstance(2024, 1, 7)), 'Domingo esperado');
        System.assertEquals(6, SEIDOR_OrderDeliveryDateAssigner.dayIndexOf(Date.newInstance(2026, 5, 10)), 'Domingo 10-05-2026 esperado');
    }

    @IsTest
    static void findNextClosestDate_diaUnicoDistintoDeHoy() {
        Date base = Date.newInstance(2026, 5, 10);
        Set<String> dias = new Set<String>{ 'Wednesday' };
        Date r = SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(base, dias);
        System.assertEquals(Date.newInstance(2026, 5, 13), r, 'Del domingo al miércoles debe ser 3 días');
    }

    @IsTest
    static void findNextClosestDate_diaUnicoIgualAHoyDevuelveSiguienteSemana() {
        Date base = Date.newInstance(2026, 5, 10);
        Set<String> dias = new Set<String>{ 'Sunday' };
        Date r = SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(base, dias);
        System.assertEquals(Date.newInstance(2026, 5, 17), r, 'Si solo hay domingos debe ir al siguiente domingo');
    }

    @IsTest
    static void findNextClosestDate_eligeElMasCercanoExcluyendoHoy() {
        Date base = Date.newInstance(2026, 5, 10);
        Set<String> dias = new Set<String>{ 'Sunday', 'Monday', 'Friday' };
        Date r = SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(base, dias);
        System.assertEquals(Date.newInstance(2026, 5, 11), r, 'El lunes (1 día) es el más cercano excluyendo el domingo de hoy');
    }

    @IsTest
    static void findNextClosestDate_setNuloODiasInvalidosDevuelveNull() {
        System.assertEquals(null, SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(Date.today(), null));
        System.assertEquals(null, SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(Date.today(), new Set<String>()));
        System.assertEquals(null, SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(null, new Set<String>{ 'Monday' }));
        System.assertEquals(
            null,
            SEIDOR_OrderDeliveryDateAssigner.findNextClosestDate(Date.today(), new Set<String>{ 'XX', 'YY' }),
            'Días no reconocidos no producen fecha'
        );
    }

    @IsTest
    static void assignDeliveryDate_asignaProximoTimeSlotDistintoDeHoy() {
        OperatingHours oh = buildOperatingHours('OH Test 1');

        String hoy = todayDayName();
        Integer hoyIdx = DAY_NAMES.indexOf(hoy);
        String otroDia = DAY_NAMES[Math.mod(hoyIdx + 2, 7)];

        buildTimeSlots(oh.Id, new List<String>{ hoy, otroDia });

        Account acc = buildAccount('Cuenta Test 1', oh.Id);
        cgcloud__Order__c o = buildOrder(acc.Id);

        Test.startTest();
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(new List<Id>{ o.Id });
        Test.stopTest();

        cgcloud__Order__c actualizada = [
            SELECT Id, cgcloud__Delivery_Date__c
            FROM cgcloud__Order__c
            WHERE Id = :o.Id
        ];

        Date esperada = expectedNextDate(otroDia);
        System.assertEquals(esperada, actualizada.cgcloud__Delivery_Date__c,
            'Debe asignarse el próximo día configurado distinto del actual');
    }

    @IsTest
    static void assignDeliveryDate_soloTimeSlotEnHoyVaSemanaSiguiente() {
        OperatingHours oh = buildOperatingHours('OH Test 2');
        String hoy = todayDayName();
        buildTimeSlots(oh.Id, new List<String>{ hoy });

        Account acc = buildAccount('Cuenta Test 2', oh.Id);
        cgcloud__Order__c o = buildOrder(acc.Id);

        Test.startTest();
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(new List<Id>{ o.Id });
        Test.stopTest();

        cgcloud__Order__c actualizada = [
            SELECT Id, cgcloud__Delivery_Date__c
            FROM cgcloud__Order__c
            WHERE Id = :o.Id
        ];

        System.assertEquals(Date.today().addDays(7), actualizada.cgcloud__Delivery_Date__c,
            'Si el único TimeSlot es hoy, debe ir al mismo día de la próxima semana');
    }

    @IsTest
    static void assignDeliveryDate_sinTimeSlotsNoModifica() {
        OperatingHours oh = buildOperatingHours('OH Test 3');
        Account acc = buildAccount('Cuenta Test 3', oh.Id);
        cgcloud__Order__c o = buildOrder(acc.Id);

        Test.startTest();
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(new List<Id>{ o.Id });
        Test.stopTest();

        cgcloud__Order__c actualizada = [
            SELECT Id, cgcloud__Delivery_Date__c
            FROM cgcloud__Order__c
            WHERE Id = :o.Id
        ];
        System.assertEquals(null, actualizada.cgcloud__Delivery_Date__c,
            'Sin TimeSlots no se debe asignar fecha');
    }

    @IsTest
    static void assignDeliveryDate_cuentaSinOperatingHoursNoModifica() {
        Account acc = buildAccount('Cuenta sin OH', null);
        cgcloud__Order__c o = buildOrder(acc.Id);

        Test.startTest();
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(new List<Id>{ o.Id });
        Test.stopTest();

        cgcloud__Order__c actualizada = [
            SELECT Id, cgcloud__Delivery_Date__c
            FROM cgcloud__Order__c
            WHERE Id = :o.Id
        ];
        System.assertEquals(null, actualizada.cgcloud__Delivery_Date__c,
            'Cuenta sin OperatingHours no debe disparar actualización');
    }

    @IsTest
    static void assignDeliveryDate_listaNulaOVaciaNoFalla() {
        Test.startTest();
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(null);
        SEIDOR_OrderDeliveryDateAssigner.assignDeliveryDate(new List<Id>());
        Test.stopTest();
    }
}
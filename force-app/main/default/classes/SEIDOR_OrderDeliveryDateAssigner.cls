/**********************************************************************************
Desarrollado por: Seidor
Proyecto: Watts
Descripción: Clase invocable desde Flow que asigna en cgcloud__Order__c.cgcloud__Delivery_Date__c
             la fecha más cercana correspondiente al próximo TimeSlot configurado en
             el OperatingHours de la cuenta asociada a la orden.
             Reglas:
               - Se ignora el TimeSlot cuyo DayOfWeek coincide con el día de ejecución
                 (se toma el siguiente más cercano).
               - Si la cuenta no tiene OperatingHours, o el OperatingHours no tiene
                 TimeSlots, no se realiza ninguna modificación.
---------------------------------------------------------------------------------
No.   Fecha           Autor                          Descripción
----- --------------- ------------------------------ ----------------------------
1.0   10-05-2026      Seidor                         Creación de la clase.
***********************************************************************************/
public with sharing class SEIDOR_OrderDeliveryDateAssigner {

    private static final Map<String, Integer> DAY_OFFSET = new Map<String, Integer>{
        'Monday'    => 0,
        'Tuesday'   => 1,
        'Wednesday' => 2,
        'Thursday'  => 3,
        'Friday'    => 4,
        'Saturday'  => 5,
        'Sunday'    => 6
    };

    /** Lunes conocido usado como referencia para calcular el día de la semana de cualquier fecha. */
    private static final Date REFERENCE_MONDAY = Date.newInstance(2024, 1, 1);

    /**
     * Método invocable desde Flow. Para cada Order recibida calcula la próxima fecha de entrega
     * según los TimeSlots del OperatingHours de la cuenta asociada.
     *
     * @param orderIds Lista de Ids de cgcloud__Order__c sobre los que se debe asignar la fecha.
     */
    @InvocableMethod(
        label='Asignar próxima fecha de entrega'
        description='Asigna en cgcloud__Delivery_Date__c la fecha del próximo TimeSlot del OperatingHours de la cuenta de la orden, excluyendo el día actual.'
    )
    public static void assignDeliveryDate(List<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        List<cgcloud__Order__c> orders = [
            SELECT Id,
                   cgcloud__Order_Account__c,
                   cgcloud__Order_Account__r.OperatingHoursId,
                   cgcloud__Delivery_Date__c
            FROM cgcloud__Order__c
            WHERE Id IN :orderIds
        ];

        System.debug('Fecha original '+ orders[0].cgcloud__Delivery_Date__c);

        if (orders.isEmpty()) {
            return;
        }

        Set<Id> operatingHoursIds = new Set<Id>();
        for (cgcloud__Order__c o : orders) {
            if (o.cgcloud__Order_Account__r != null && o.cgcloud__Order_Account__r.OperatingHoursId != null) {
                operatingHoursIds.add(o.cgcloud__Order_Account__r.OperatingHoursId);
            }
        }

        if (operatingHoursIds.isEmpty()) {
            return;
        }

        Map<Id, Set<String>> daysByOperatingHours = new Map<Id, Set<String>>();
        for (TimeSlot ts : [
            SELECT OperatingHoursId, DayOfWeek
            FROM TimeSlot
            WHERE OperatingHoursId IN :operatingHoursIds
        ]) {
            Set<String> days = daysByOperatingHours.get(ts.OperatingHoursId);
            if (days == null) {
                days = new Set<String>();
                daysByOperatingHours.put(ts.OperatingHoursId, days);
            }
            days.add(ts.DayOfWeek);
        }

        Date today = Date.today();
        List<cgcloud__Order__c> toUpdate = new List<cgcloud__Order__c>();

        for (cgcloud__Order__c o : orders) {
            if (o.cgcloud__Order_Account__r == null) {
                continue;
            }
            Id ohId = o.cgcloud__Order_Account__r.OperatingHoursId;
            if (ohId == null) {
                continue;
            }
            Set<String> days = daysByOperatingHours.get(ohId);
            if (days == null || days.isEmpty()) {
                continue;
            }

            Date nextDate = findNextClosestDate(today, days);
            if (nextDate != null) {
                toUpdate.add(new cgcloud__Order__c(
                    Id = o.Id,
                    cgcloud__Delivery_Date__c = nextDate,
                    Fecha_Actualizada__c = true
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('Órdenes actualizadas: ' + toUpdate.size());
        }

        System.debug('Fin de la asignación');
    }

    /**
     * Devuelve la fecha del próximo día de la semana presente en {@code daysOfWeek},
     * excluyendo el mismo {@code startDate}. Si el único día configurado coincide con
     * {@code startDate}, se devuelve la fecha 7 días después.
     *
     * @param startDate   Fecha base (típicamente hoy).
     * @param daysOfWeek  Conjunto de días en inglés (Monday, Tuesday, ...).
     * @return            Fecha calculada o null si no hay días válidos.
     */
    @TestVisible
    private static Date findNextClosestDate(Date startDate, Set<String> daysOfWeek) {
        if (startDate == null || daysOfWeek == null || daysOfWeek.isEmpty()) {
            return null;
        }

        Integer todayIdx = dayIndexOf(startDate);
        Integer minDays = null;

        for (String dayName : daysOfWeek) {
            Integer offset = DAY_OFFSET.get(dayName);
            if (offset == null) {
                continue;
            }
            Integer diff = Math.mod(offset - todayIdx + 7, 7);
            if (diff == 0) {
                diff = 7;
            }
            if (minDays == null || diff < minDays) {
                minDays = diff;
            }
        }

        if (minDays == null) {
            return null;
        }
        return startDate.addDays(minDays);
    }

    /**
     * Calcula el índice del día de la semana de una fecha (0 = lunes, 6 = domingo)
     * a partir de un lunes de referencia conocido (2024-01-01).
     */
    @TestVisible
    private static Integer dayIndexOf(Date d) {
        Integer daysSinceRef = REFERENCE_MONDAY.daysBetween(d);
        Integer mod = Math.mod(daysSinceRef, 7);
        if (mod < 0) {
            mod += 7;
        }
        return mod;
    }
}
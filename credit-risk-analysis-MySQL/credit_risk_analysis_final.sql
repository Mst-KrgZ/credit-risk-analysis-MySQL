/* ============================================================
   Projekt A – Credit Risk Analyse
   Author: Mesut Karagöz
   Tool: MySQL
   Dataset: credit_risk_dataset.csv
   Rows: 32.581
   ============================================================ */
/* ============================================================
   Phase 0 – Einrichtung & Datenimport
   ============================================================ */
   
SET GLOBAL local_infile = 1;     -- Lokale Dateizugriffe erlauben

CREATE DATABASE IF NOT EXISTS credit_risk_dataset;  -- Datenbank erstellen

USE credit_risk_dataset;   -- Datenbank auswählen

SELECT DATABASE();      -- Aktive Datenbank prüfen

-- Tabelle erstellen
CREATE TABLE credit_risk (
    person_age INT,
    person_income INT,
    person_home_ownership VARCHAR(20),
    person_emp_length DOUBLE NULL,
    loan_intent VARCHAR(30),
    loan_grade VARCHAR(5),
    loan_amnt INT,
    loan_int_rate DOUBLE NULL,
    loan_status INT,
    loan_percent_income DOUBLE,
    cb_person_default_on_file VARCHAR(5),
    cb_person_cred_hist_length INT
);

DESCRIBE credit_risk; -- Tabellenstruktur prüfen

SELECT * FROM credit_risk; -- Inhalt vorab anzeigen

USE credit_risk_dataset; -- Datenbank auswählen

-- Datenimport 
LOAD DATA LOCAL INFILE 'C:/Users/Mesut/Desktop/03_Abschlussprojekt/credit_risk_dataset.csv'
INTO TABLE credit_risk
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    person_age,
    person_income,
    person_home_ownership,
    @emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    @int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length
)
SET
    person_emp_length = NULLIF(@emp_length, ''),
    loan_int_rate = NULLIF(@int_rate, '');
    
SELECT * FROM credit_risk;  -- Daten prüfen 

SELECT COUNT(*) FROM credit_risk;  -- Anzahl der Datensätze

-- ************************** Phase 1 – Explorative Datenanalyse (EDA) ********************************** 
-- 1.1 Datenumfang
SELECT COUNT(*) FROM credit_risk;  -- (32.581 Datensätze).

DESCRIBE credit_risk;  -- 1.2 Spalten & Datentypen

-- 1.3 Fehlende Werte (Data Quality)
SELECT
  SUM(person_age IS NULL)              		  AS fehlend_person_age,
  SUM(person_income IS NULL)           		  AS fehlend_person_income,
  SUM(person_home_ownership IS NULL)   		  AS fehlend_home_ownership,
  SUM(person_emp_length IS NULL)     	 	  AS fehlend_emp_length,      -- 895
  SUM(loan_intent IS NULL)           	      AS fehlend_loan_intent,
  SUM(loan_grade IS NULL)           	      AS fehlend_loan_grade,
  SUM(loan_amnt IS NULL)               		  AS fehlend_loan_amnt,
  SUM(loan_int_rate IS NULL)          	      AS fehlend_loan_int_rate,   -- 3116
  SUM(loan_status IS NULL)              	  AS fehlend_loan_status,
  SUM(loan_percent_income IS NULL)      	  AS fehlend_loan_percent_income,
  SUM(cb_person_default_on_file IS NULL)	  AS fehlend_default_on_file,
  SUM(cb_person_cred_hist_length IS NULL)	  AS fehlend_cred_hist_length
FROM credit_risk;

-- Fehlende Werte treten nur in zwei Spalten auf.
-- Ich habe mich bewusst auf diese konzentriert, da sie fachlich relevant sind:
-- person_emp_length: Indikator für Beschäftigungsstabilität
-- loan_int_rate: zentral für Risikoabschätzung und Kredit-Pricing
-- Der Anteil fehlender Werte ist moderat, daher erfolgt die gezielte Behandlung in Phase 2.

-- 1.4 Verteilungen & Wertebereiche
-- 1.4.1 Alter (person_age)
SELECT
  MIN(person_age)             AS min_alter,       -- 20
  MAX(person_age)             AS max_alter,		  -- 144
  ROUND(AVG(person_age), 1)   AS avg_alter		  -- 27.7
FROM credit_risk;

-- 1.4.1 Alter (Fortsetzung)
-- Prüfung der höchsten Alterswerte
SELECT
  person_age
FROM credit_risk
WHERE person_age IS NOT NULL
ORDER BY person_age DESC
LIMIT 10;				--	144, 144, 144, 123, 123, 94, 84, 80, 78, 76

-- 1.4.1 Alter (zusätzliche Prüfung)
-- Häufigkeitsanalyse hoher Alterswerte
SELECT
  person_age,
  COUNT(*) AS anzahl
FROM credit_risk
WHERE person_age IS NOT NULL
GROUP BY person_age
ORDER BY person_age DESC
LIMIT 10;				-- 	144 * 3, 123 * 2, 94 * 1, 84 * 1, 80 * 1, 78 *1 , 76 * 1, 73 * 3, 70 * 7, 69 * 5 
-- Das Alter eignet sich für eine abgestufte Gewichtung im Risikoscore.
-- Mit zunehmendem Alter steigt der Einfluss auf den Score (z. B. niedriger Faktor bis 60,
-- höherer Faktor im hohen Alter).
-- Die konkrete Ausgestaltung erfolgt bewusst in einer späteren Phase.

-- 1.4.1 Alter (zusätzliche Prüfung)
-- Prüfung der niedrigsten Alterswerte
SELECT
  person_age
FROM credit_risk
WHERE person_age IS NOT NULL
ORDER BY person_age
LIMIT 1;
-- Mindestalter 20 Jahre.
-- Keine Beobachtungen unter 18 → Datenqualität unkritisch.

-- 1.4.1 Alter (zusätzliche Prüfung) -- Häufigkeitsanalyse niedriger Alterswerte
SELECT
  person_age,
  COUNT(*) AS anzahl
FROM credit_risk
WHERE person_age IS NOT NULL
GROUP BY person_age
ORDER BY person_age
LIMIT 10;
-- Altersverteilung konzentriert sich auf frühe 20er. -- Portfolio ist überwiegend jung.

-- 1.4.2 Einkommen (person_income)
SELECT
  MIN(person_income) AS min_income,      -- 4.000
  MAX(person_income) AS max_income,      -- 6.000.000
  ROUND(AVG(person_income),1) AS avg_income  -- 66.074,8
FROM credit_risk;
-- Die Einkommensverteilung ist sehr breit.
-- Der Durchschnitt wird deutlich durch hohe Ausreißer verzerrt.
-- Daher wird das Einkommen in der Risikoanalyse segmentbasiert betrachtet.

-- 1.4.2 Einkommen (Zusatzanalyse) -- Prüfung der höchsten Einkommenswerte
SELECT
  person_income AS income,
  COUNT(*) AS anzahl
FROM credit_risk
GROUP BY person_income
ORDER BY person_income DESC
LIMIT 10;
-- Sehr hohe Einkommen treten nur in wenigen Beobachtungen auf
-- und verzerren den Durchschnitt nach oben.
-- Diese Auffälligkeiten wurden im Rahmen der Datenqualitätsprüfung dokumentiert.

-- 1.4.2 Einkommen (Zusatzanalyse)
SELECT
    person_age,
    person_income,
    COUNT(*) AS anzahl
FROM credit_risk
GROUP BY person_age, person_income
ORDER BY person_income DESC
LIMIT 10;
-- Die höchsten Einkommen verteilen sich auf unterschiedliche Altersgruppen
-- und konzentrieren sich nicht auf ein einzelnes Alterssegment.
-- Es handelt sich um vereinzelte Beobachtungen mit jeweils nur einem Fall.
-- Diese Ergebnisse sprechen gegen systematische Datenfehler
-- und unterstützen die Entscheidung, die Werte nicht zu bereinigen.

-- 1.4.2 Einkommen (Zusatzanalyse)
-- Prüfung der niedrigsten Einkommenswerte
SELECT
  person_income AS income,
  COUNT(*) AS cnt
FROM credit_risk
GROUP BY person_income
ORDER BY person_income
LIMIT 10;
-- Die niedrigsten Einkommen treten nur in einer begrenzten Anzahl von Beobachtungen auf.
-- Diese Werte beeinflussen die Gesamtstruktur des Datensatzes nicht wesentlich.

-- 1.4.2 Einkommen (Zusatzanalyse)
-- Durchschnittlicher Kreditbetrag bei hohen Einkommen
SELECT
  person_income AS income,
  COUNT(*) AS cnt,
  ROUND(AVG(loan_amnt),0) AS avg_loan_amount
FROM credit_risk
GROUP BY person_income
ORDER BY person_income DESC
LIMIT 10;
-- In hohen Einkommensgruppen ist der durchschnittliche Kreditbetrag vergleichsweise niedrig.
-- Dies kann darauf hindeuten, dass Kunden mit hohem Einkommen einen geringeren
-- Finanzierungs- bzw. Verschuldungsbedarf haben.
-- im Hinblick auf die Datenkonsistenz erneut geprüft.

-- 1.4.2 Einkommen (Zusatzanalyse) -- Beispiele für hohes Einkommen – Kreditbetrag
SELECT
  person_income AS income,
  loan_amnt AS loan_amount
FROM credit_risk
ORDER BY income DESC
LIMIT 10;
-- Bei Kreditnehmern mit sehr hohem Einkommen sind die Kreditbeträge vergleichsweise niedrig.
-- Ein hohes Einkommen führt nicht automatisch zu einer hohen Kreditinanspruchnahme.
-- Einkommen und Kreditbetrag sollten gemeinsam bewertet werden.

-- 1.4.2 Einkommen (Zusatzanalyse)
-- Beispiele für niedriges Einkommen – Kreditbetrag
SELECT
  person_income AS income,
  loan_amnt AS loan_amount
FROM credit_risk
ORDER BY income
LIMIT 10;
-- In niedrigen Einkommensgruppen sind die Kreditbeträge im Verhältnis zum Einkommen vergleichsweise hoch.
-- Dies deutet auf ein potenziell erhöhtes Risikoprofil hin.
-- für eine Konsistenz- und Plausibilitätsprüfung herangezogen.

-- 1.4.2 Einkommen (Zusatzanalyse) -- Durchschnittlicher Kreditbetrag bei niedrigen Einkommen
SELECT
  person_income AS income,
  COUNT(*) AS cnt,
  ROUND(AVG(loan_amnt),0) AS avg_loan_amount
FROM credit_risk
GROUP BY person_income
ORDER BY person_income
LIMIT 10;
-- In niedrigen Einkommensgruppen ist der durchschnittliche Kreditbetrag vergleichsweise hoch.
-- Dies kann darauf hindeuten, dass Kunden mit niedrigem Einkommen
-- im Verhältnis zu ihrem Einkommen stärker verschuldet sind.

-- 1.4.2 Einkommen (Zusatzanalyse) -- Kreditzwecke von Kreditnehmern mit sehr niedrigem Einkommen
SELECT
    loan_intent,
    COUNT(*) AS cnt
FROM credit_risk
WHERE person_income <= 5000
GROUP BY loan_intent
ORDER BY cnt DESC;

-- 1.4.2 Einkommen (Zusatzanalyse) --  Wird der Durchschnitt durch Extremwerte beeinflusst?
SELECT
  ROUND(AVG(person_income),1) AS avg_income,   -- 66.074,8
  MIN(person_income) AS min_income,            -- 4.000
  MAX(person_income) AS max_income,            -- 6.000.000
  ROUND(STDDEV(person_income),1) AS std_income  -- 61982.2
FROM credit_risk;

-- Die Standardabweichung liegt nahe am Durchschnittswert
-- und weist auf eine Verzerrung durch sehr hohe Einkommen hin.
-- Das Einkommen wird daher nicht isoliert, sondern segmentbasiert analysiert.

-- 1.4.2 Einkommen (Gruppierung) -- Segmentanalyse zur besseren Einordnung der Einkommensverteilung
SELECT
  CASE
    WHEN person_income < 20000 THEN '< 20k'
    WHEN person_income < 40000 THEN '20k–40k'
    WHEN person_income < 60000 THEN '40k–60k'
    WHEN person_income < 100000 THEN '60k–100k'
    ELSE '> 100k'
  END AS income_group,
  COUNT(*) AS cnt
FROM credit_risk
GROUP BY income_group
ORDER BY cnt DESC;
-- Die Einkommen konzentrieren sich überwiegend im Bereich von 40k–100k.
-- Die Einkommensgruppe unter 20k ist im Datensatz nur in begrenztem Umfang vertreten.
-- Sehr hohe Einkommen (z. B. 6.000.000) sind für die Verteilungsanalyse nicht repräsentativ.

-- 1.4.3 Einkommen × Risiko -- Steigt das Ausfallrisiko bei sinkendem Einkommen?
SELECT
  CASE
    WHEN person_income < 20000 THEN '< 20k'
    WHEN person_income < 40000 THEN '20k–40k'
    WHEN person_income < 60000 THEN '40k–60k'
    WHEN person_income < 100000 THEN '60k–100k'
    ELSE '> 100k'
  END AS income_group,
  COUNT(*) AS total,
  SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS default_count
FROM credit_risk
GROUP BY income_group
ORDER BY income_group;
-- Besonders die Gruppe unter 20k weist das höchste Risikoniveau auf.
-- Das Einkommen stellt damit einen zentralen Risikofaktor dar.

-- 1.5 Zielvariable: Kreditausfall (loan_status) -- Anzahl der Ausfälle (erste Prüfung)
SELECT
  loan_status,            -- 1 = Ausfall, 0 = kein Ausfall
  COUNT(*) AS loan_count  -- 1 -> 7108 ,    0 -> 25473 
FROM credit_risk
GROUP BY loan_status;
-- Die numerische Verteilung ausgefallener und nicht ausgefallener Kredite wird dargestellt.

-- 1.5 Zielvariable: Kreditausfall (Fortsetzung) -- Ausfallquote (Baseline-Risiko)
SELECT
  loan_status,
  COUNT(*) AS loan_count,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM credit_risk) * 100, 2) AS pct   -- 1 -> %21.82    0 -> % 78.18
FROM credit_risk
GROUP BY loan_status;
-- Rund 21,8 % der Kredite sind ausgefallen.
-- Dieser Wert definiert das Baseline-Risikoniveau des Portfolios
-- und dient als Referenz für alle weiteren Analysen.

-- 1.6 Kategorische Variablen – Bonitätsklasse (loan_grade) -- Verteilung der Kreditbonität
SELECT
  loan_grade,
  COUNT(*) AS cnt
FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;
-- Die Kreditbonitätsklassen reichen von A bis G.
-- Die Verteilung konzentriert sich überwiegend auf die Klassen A und B,
-- während F und G nur wenige Beobachtungen enthalten.
-- loan_grade ist eine zentrale Variable für die Risikobewertung.

-- 1.6 Kategorische Variablen – Wohnsituation -- Verteilung der Wohnsituation
SELECT
  person_home_ownership,
  COUNT(*) AS cnt
FROM credit_risk
GROUP BY person_home_ownership;
-- Die Mehrheit der Kreditnehmer befindet sich in den Wohnsituationen RENT oder MORTGAGE.
-- Die Gruppe OWN ist deutlich geringer vertreten.
-- Die Wohnsituation kann als potenzieller Stabilitätsindikator herangezogen werden.

-- 1.6.3 Frühere Zahlungsausfälle -- Frühere Zahlungsausfälle
SELECT
  cb_person_default_on_file,
  COUNT(*) AS cnt
FROM credit_risk
GROUP BY cb_person_default_on_file;  -- Sehr wichtig für Vorstandssorge!
-- Historische Zahlungsausfälle stellen einen starken Risikofaktor dar.
-- Die Mehrheit der Kreditnehmer weist keine früheren Defaults auf,
-- jedoch existiert eine relevante Gruppe mit Zahlungshistorie.
-- Diese Variable ist ein zentraler Indikator zur Erklärung des Kreditrisikos.

-- 1️ loan_percent_income (sehr kritisch) -- Analyse der Kreditbelastung (Anteil am Einkommen)
SELECT
  MIN(loan_percent_income) AS min_lpi,            -- 0 
  MAX(loan_percent_income) AS max_lpi,            -- 0.83
  ROUND(AVG(loan_percent_income),2) AS avg_lpi    -- 0.17
FROM credit_risk;
-- loan_percent_income bildet die finanzielle Belastung des Kreditnehmers direkt ab.
-- Hohe Werte stellen ein klares Risikosignal dar.

-- 2 loan_int_rate (Pricing-Logik) -- Ist der Zinssatz mit dem Risiko abgestimmt?
SELECT
  loan_grade,
  ROUND(AVG(loan_int_rate),2) AS avg_rate
FROM credit_risk
GROUP BY loan_grade
ORDER BY loan_grade;
-- Der Zinssatz steigt von Bonitätsklasse A bis G monoton an.
-- Dies zeigt, dass die Bank ihre Preisgestaltung risikobasiert vornimmt.
-- loan_int_rate ist eine risiko­-sensitive Variable

-- 3 loan_intent (Verwendungszweck) -- Risikoverteilung nach Kreditverwendungszweck
SELECT
  loan_intent,
  COUNT(*) AS total_kredite,
  SUM(loan_status) AS anzahl_ausfaelle
FROM credit_risk
GROUP BY loan_intent
ORDER BY anzahl_ausfaelle DESC;
-- Bei den Verwendungszwecken MEDICAL und DEBT CONSOLIDATION treten deutlich mehr Ausfälle auf.
-- Der Kreditverwendungszweck ist damit ein relevanter Faktor zur Erklärung des Kreditrisikos.

-- 4 person_emp_length (Beschäftigungsstabilität) -- Beschäftigungsdauer / Beschäftigungsstabilität
SELECT
  MIN(person_emp_length) AS min_emp,        -- 0
  MAX(person_emp_length) AS max_emp,        -- 123
  ROUND(AVG(person_emp_length),1) AS avg_emp -- 4.8
FROM credit_risk;
-- Die Beschäftigungsdauer weist einzelne nicht plausible Werte auf.
-- person_emp_length ist ein relevanter Indikator für Stabilität
-- und damit für das Kreditrisiko.

-- 5 cb_person_cred_hist_length (Kredithistorie)
-- Dauer der Kredithistorie / finanzielle Erfahrung
SELECT
  MIN(cb_person_cred_hist_length) AS min_hist,        -- 2
  MAX(cb_person_cred_hist_length) AS max_hist,        -- 30
  ROUND(AVG(cb_person_cred_hist_length),1) AS avg_hist -- 5.8
FROM credit_risk;
-- Eine längere Kredithistorie deutet auf ein stabileres
-- und tendenziell risikoärmeres Kundenprofil hin.
-- Die Variable ist für die Risikodifferenzierung in Phase 3 relevant.

/*Phase 1 – Zusammenfassung
Der Datensatz mit 32.581 Kreditfällen ist für eine Risikoanalyse geeignet
und enthält eine klare Zielvariable (loan_status).
Fehlende Werte sind begrenzt und kontrollierbar.
In Einkommen, Kreditbetrag, Bonitätsklasse und Beschäftigung
zeigen sich erste deutliche Risikomuster.
In dieser Phase wurden keine Daten verändert,
sondern gezielt analysiert und verstanden.
*/

-- ********************* Phase 2  Datenqualität & Datenbereinigung   ************************

-- An dieser Stelle wurde eine separate Analysetabelle erstellt,
-- um mögliche Schritte der Datenbereinigung und -korrektur
-- kontrolliert und nachvollziehbar umsetzen zu können.
-- Dieser Ansatz dient dem Schutz der Rohdaten
-- und gewährleistet einen transparenten Analyseprozess.

CREATE TABLE IF NOT EXISTS credit_risk_clean AS
SELECT *
FROM credit_risk;

SELECT * FROM credit_risk_clean;
DESCRIBE credit_risk_clean;
-- Row count
SELECT COUNT(*) FROM credit_risk_clean; -- Es liegen 32.581 Datensätze vor.

-- 2.2 Analyse fehlender Werte (NULL-Analyse)
SELECT
    SUM(person_emp_length IS NULL) AS null_emp_length,  -- 895
    SUM(loan_int_rate IS NULL)     AS null_int_rate     -- 3116
FROM credit_risk_clean;

-- 2.1.2 Prozentualer Anteil der NULL-Werte
SELECT
    ROUND(SUM(person_emp_length IS NULL) / COUNT(*) * 100, 2) AS pct_null_emp_length,  -- %2.75
    ROUND(SUM(loan_int_rate IS NULL) / COUNT(*) * 100, 2)     AS pct_null_int_rate     -- %9.56
FROM credit_risk_clean;
-- person_emp_length: geringer Anteil fehlender Werte (2,75 %)
-- loan_int_rate: moderater Anteil fehlender Werte (9,56 %)

-- 2.2.1 Verteilung der NULL-Werte nach loan_status
SELECT
    loan_status,
    COUNT(*) AS total,
    SUM(loan_int_rate IS NULL) AS null_rates
FROM credit_risk_clean
GROUP BY loan_status;

-- 2.2.2 Prozentuale NULL-Verteilung nach loan_status -- Prozentuale NULL-Anteile nach Kreditstatus
SELECT
    loan_status,
    COUNT(*) AS total_records,
    SUM(loan_int_rate IS NULL) AS null_count,
    ROUND(SUM(loan_int_rate IS NULL) / COUNT(*) * 100, 2) AS pct_null
FROM credit_risk_clean
GROUP BY loan_status;
/*
1	7108	644		%9.06     -- Die NULL-Anteile in den Default- und Non-Default-Gruppen sind ähnlich hoch.
0	25473	2472	%9.70     -- Für loan_int_rate ist keine systematische Häufung in einer bestimmten Risikogruppe erkennbar.
*/
-- Die fehlenden Werte sind zufällig verteilt.

-- ADIM 2.3 – Robustheitsprüfung (Shadow Analysis)
-- Ziel: Vergleich der Ausfallquote mit und ohne fehlende Zinssätze
-- Szenario A: Gesamtdatensatz
SELECT
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS ausfallquote_gesamt -- Ausfallquote gesamt     ≈ 21,8 %
FROM credit_risk_clean;

-- Szenario B: Nur Datensätze mit vorhandenem Zinssatz
SELECT
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS ausfallquote_ohne_null  -- Ausfallquote ohne NULL ≈ 21,9 %
FROM credit_risk_clean
WHERE loan_int_rate IS NOT NULL;
-- Das Entfernen fehlender Zinssätze verändert die Ausfallquote nicht wesentlich.
-- Fehlende Zinssätze verursachen somit keinen systematischen Bias.
-- Analysen zum Zinssatz können auf vollständige Datensätze beschränkt werden,
-- ohne die Aussagekraft der Ergebnisse zu beeinträchtigen.


-- ADIM 2.4 – Zusammenhang zwischen Bonitätsklasse und Zinssatz
SELECT
    loan_grade AS bonitaetsklasse,
    COUNT(*) AS anzahl_kredite,
    ROUND(AVG(loan_int_rate), 2) AS durchschnittlicher_zinssatz
FROM credit_risk_clean
WHERE loan_int_rate IS NOT NULL
GROUP BY bonitaetsklasse
ORDER BY bonitaetsklasse;
/*
A   9.774   7,33		 
B   9.395  11,00	   	 -- Der durchschnittliche Zinssatz steigt mit abnehmender Bonitätsklasse systematisch an.
C   5.828  13,46         -- Zwischen Bonitätsklasse und Zinssatz besteht ein klarer und konsistenter Zusammenhang.
D   3.314  15,36         -- Der Zinssatz wird maßgeblich durch die Bonitätsklasse bestimmt.
E     881  17,01		 -- Eine Imputation fehlender Zinssätze auf Basis der Bonitätsklasse ist daher fachlich begründbar.
F     214  18,61
G      59  20,25
*/

-- 2.2 Plausibilitätsprüfung & Ausreißeranalyse 
-- Schritt 1: Wertebereiche prüfen 
SELECT
    MIN(person_age) AS min_age,		-- 20 
    MAX(person_age) AS max_age,		-- 144
    MIN(person_income) AS min_income, -- 4000
    MAX(person_income) AS max_income, -- 6000000
    MIN(loan_amnt) AS min_loan,		-- 500
    MAX(loan_amnt) AS max_loan,		-- 35000
    MIN(loan_int_rate) AS min_rate,	-- %5.42
    MAX(loan_int_rate) AS max_rate	-- %23.22
FROM credit_risk_clean;

-- Schritt 2: Kritische Kandidaten gezielt prüfen
-- Alter
SELECT *
FROM credit_risk_clean
WHERE person_age < 18 OR person_age > 80;      -- 144, 123, 94, 84 
-- Ein Alter von 65 oder über 70 Jahren stellt keinen Datenfehler dar.
-- Diese Werte sind durch reale Kundenprofile erklärbar
-- (z. B. Selbstständige, vermögende Personen oder Rentner 

SELECT
    person_age,
    person_income,
    loan_intent,
    loan_grade,
    person_emp_length
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL;
-- Plausibilitätsprüfung: Beschäftigungsdauer im Verhältnis zum Alter
-- Annahme: frühester Arbeitsbeginn mit 18 Jahren

SELECT
    person_age,
    person_emp_length,
    (person_age - 18) AS max_moegliche_beschaeftigungsdauer
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
  AND person_emp_length > (person_age - 18)
ORDER BY person_emp_length DESC;

/*
22   | 123 | 4                    
21   | 123 | 3
*/
-- Beschäftigungsdauer liegt sehr nahe bei Alter − 18
-- Das heißt: „Grenzüberschreitung“

-- Zusatzanalyse
SELECT
    COUNT(*) AS anzahl_unplausible_faelle
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
  AND person_emp_length > (person_age - 18);  
-- 7.836 Fälle weisen Unklarheiten bei der Beschäftigungsdauer auf.
-- Eine Klärung mit den Fachbereichen wäre sinnvoll
-- (offizielle Nachweise vs. Selbstauskunft).
-- Empfehlung: Beim Aufbau eines operativen Systems sollte diese Information klar definiert werden.

-- 🧠 Schritt 1.2 – Besteht ein Zusammenhang zwischen Alter und Beschäftigungsdauer?
-- Nicht vermuten, sondern datenbasiert prüfen.
SELECT
    CASE
        WHEN person_age < 25 THEN 'young'
        WHEN person_age BETWEEN 25 AND 40 THEN 'mid'
        ELSE 'senior'
    END AS age_group,
    COUNT(*) AS cnt,
	ROUND(AVG(person_emp_length), 2) AS avg_emp_length
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY age_group;
-- Die durchschnittliche Beschäftigungsdauer steigt mit zunehmendem Alter
-- der Kreditnehmer systematisch an.
-- Das Alter stellt einen erklärenden Faktor für die Beschäftigungsdauer dar
-- und kann als sinnvolle Dimension für eine spätere Imputation herangezogen werden.


-- 🪜 Schritt 1.3 – Einfluss der Bonitätsklasse (loan_grade)
-- Prüfung des Zusammenhangs zwischen bankinterner Risikoklassifizierung und Beschäftigungsdauer.
SELECT
  loan_grade,
  COUNT(*)                         AS anzahl,
  ROUND(AVG(person_emp_length), 2) AS avg_beschaeftigungsdauer,
  ROUND(AVG(person_age), 2)        AS avg_alter
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY loan_grade
ORDER BY loan_grade;
-- Die durchschnittliche Beschäftigungsdauer nimmt von Bonitätsklasse A bis F ab.
-- Die Abweichung in Klasse G ist aufgrund der geringen Fallzahl nicht belastbar.
-- Insgesamt besteht ein plausibler Zusammenhang zwischen Bonitätsklasse
-- und Beschäftigungsdauer.
-- Die Bonitätsklasse eignet sich damit als erklärender Faktor
-- für spätere Imputations- oder Segmentierungsentscheidungen.

SELECT
    person_home_ownership,
    COUNT(*) AS cnt
FROM credit_risk_clean
WHERE loan_grade = 'G'
GROUP BY person_home_ownership
ORDER BY cnt DESC;

SELECT
    loan_intent,
    COUNT(*) AS cnt
FROM credit_risk_clean
WHERE loan_grade = 'G'
GROUP BY loan_intent
ORDER BY cnt DESC;

-- 🧠 Schritt 1.4 – Hat der Kreditverwendungszweck (loan_intent) einen Einfluss?
SELECT
    loan_intent,
    COUNT(*) AS cnt,
    ROUND(AVG(person_emp_length), 2) AS avg_emp_length
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY loan_intent
ORDER BY avg_emp_length DESC;
-- Die durchschnittliche Beschäftigungsdauer variiert je nach Kreditabsicht.
-- HOMEIMPROVEMENT ist mit längerer, EDUCATION mit kürzerer Beschäftigungsdauer verbunden.
-- Der Effekt ist vorhanden, jedoch schwächer als bei Alter oder Bonitätsklasse.
-- Die Kreditabsicht stellt damit einen unterstützenden,
-- aber nicht dominanten Faktor für spätere Segmentierung oder Imputation dar.

-- 🪜 Schritt 1.5 – Ist das Einkommen ein erklärender Faktor? 
-- Grundprinzip:
-- Einkommen wird nicht als Rohwert analysiert,
-- sondern in sinnvolle Einkommensgruppen segmentiert,
-- um strukturelle Unterschiede sichtbar zu machen.

-- Schritt 1.5.1 – Bildung von Einkommensgruppen
SELECT
    CASE
        WHEN person_income < 30000 THEN 'low_income'
        WHEN person_income BETWEEN 30000 AND 60000 THEN 'mid_income'
        ELSE 'high_income'
    END AS income_group,
    COUNT(*) AS cnt,
    ROUND(AVG(person_emp_length), 2) AS avg_emp_length
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY income_group;
-- Mit steigendem Einkommen nimmt die durchschnittliche Beschäftigungsdauer deutlich zu.
-- Zwischen Einkommen und Beschäftigungsdauer besteht ein klarer Zusammenhang.
-- Das Einkommen stellt damit einen erklärenden,
-- jedoch ergänzenden Faktor dar und kann unterstützend
-- für spätere Analysen oder Imputationsentscheidungen herangezogen werden.

-- 🔹 Schritt 1.5.2 – Einkommen und Alter gemeinsam betrachtet 
-- Ein Einkommen von 80k mit 25 Jahren ist nicht gleichzusetzen mit 80k bei 45 Jahren.
SELECT
  CASE
    WHEN person_age < 25 THEN 'young'
    WHEN person_age BETWEEN 25 AND 40 THEN 'mid'
    ELSE 'senior'
  END AS age_group,
  CASE
    WHEN person_income < 30000 THEN 'low_income'
    WHEN person_income BETWEEN 30000 AND 60000 THEN 'mid_income'
    ELSE 'high_income'
  END AS income_group,
  COUNT(*)                         AS anzahl,
  ROUND(AVG(person_emp_length), 2) AS avg_beschaeftigungsdauer
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY age_group, income_group
ORDER BY age_group, income_group; 
-- Innerhalb jeder Altersgruppe steigt die durchschnittliche Beschäftigungsdauer
-- mit zunehmendem Einkommen.
-- Der Effekt ist bereits bei jüngeren Kreditnehmern sichtbar
-- und verstärkt sich mit zunehmendem Alter.
-- Einkommen und Alter leisten jeweils einen eigenständigen Beitrag
-- zur Erklärung der Beschäftigungsdauer.

-- SCHRITT 1.6 – Referenztabelle
SELECT
    loan_grade,
    CASE
        WHEN person_age < 25 THEN 'young'
        WHEN person_age BETWEEN 25 AND 40 THEN 'mid'
        ELSE 'senior'
    END AS age_group,
    CASE
        WHEN person_income < 30000 THEN 'low_income'
        WHEN person_income BETWEEN 30000 AND 60000 THEN 'mid_income'
        ELSE 'high_income'
    END AS income_group,
    COUNT(*) AS cnt,
    ROUND(AVG(person_emp_length), 2) AS avg_emp_length
FROM credit_risk_clean
WHERE person_emp_length IS NOT NULL
GROUP BY loan_grade, age_group, income_group
ORDER BY loan_grade, age_group, income_group;
-- Die Einkommensverteilung ist rechtsschief.
-- Eine Schwelle von 60k trennt den mittleren und hohen Einkommensbereich zu früh.
-- Eine Grenze von 70k liegt näher an einer natürlichen Verteilungsgrenze.

-- Der oben verwendete Betrag von 50.000 erscheint für unseren Datensatz,
-- dessen Maximalwert bei 35.000 liegt, nicht sinnvoll.
-- Richtiger Schritt 1: Zunächst die Verteilung prüfen
SELECT
    MIN(loan_amnt)              AS min_loan,   -- 500
    MAX(loan_amnt)              AS max_loan,   -- 35000
    ROUND(AVG(loan_amnt), 1)    AS avg_loan,   -- 9589.4
    ROUND(STDDEV(loan_amnt), 1) AS std_loan    -- 6322
FROM credit_risk_clean;

-- Kreditsumme -- Analyse hoher Kreditsummen auf Basis datengetriebener Schwellen
SELECT *
FROM credit_risk_clean
WHERE loan_amnt >= 35000;
-- Hohe Kreditbeträge wurden relativ zum Wertebereich des Datensatzes bewertet
-- und nicht anhand fixer externer Schwellen.
-- Hohe Kreditsummen bei hohem Einkommen sind plausibel und für die Risikoanalyse besonders relevant.

-- Als nächster Schritt wurde eine datenbasierte Definition von Ausreißern gewählt.
-- Da echte Perzentile in MySQL nur eingeschränkt verfügbar sind,
-- erfolgt die Abgrenzung über streuungsbasierte Schwellenwerte.
SELECT *
FROM credit_risk_clean
WHERE loan_amnt > (
    SELECT AVG(loan_amnt) + 2 * STDDEV(loan_amnt)
    FROM credit_risk_clean
);
-- Dies entspricht einer Abgrenzung oberhalb von Mittelwert plus zwei Standardabweichungen
-- und ist datenbasiert sowie analytisch gut begründbar.

-- Eine isoliert hohe Kreditsumme stellt noch keinen Ausreißer dar.
-- Eine gemeinsame Betrachtung mit dem Einkommen ist daher aussagekräftiger.
SELECT *
FROM credit_risk_clean
WHERE loan_amnt > 30000
  AND loan_percent_income > 0.6;
-- Entscheidend ist nicht nur die absolute Kredithöhe,
-- sondern deren Verhältnis zum Einkommen.
-- Diese Logik folgt der Risikobetrachtung und nicht reiner Statistik.
-- Verwendete Schwellen dienen als heuristische Orientierung
-- und können in späteren Analysen datenbasiert angepasst werden.

-- In Phase 2 wird klar zwischen statistischen und risikobasierten Grenzen unterschieden.
-- Mittelwert plus Standardabweichung beschreibt eine statistische Abgrenzung,
-- während feste Schwellen risikobasierte Geschäftsregeln darstellen.
-- Beide Ansätze sind unterschiedlich, können jedoch sinnvoll kombiniert werden.
-- Zinssatz
SELECT *
FROM credit_risk_clean
WHERE loan_int_rate > 30;
-- Hohe Zinssätze stellen keinen Datenfehler dar,
-- sondern ein klares Risikosignal.
-- Auffällige Werte wurden bewusst nicht entfernt
-- und aktiv für die Risikodifferenzierung beibehalten.

-- Datenkonsistenz – Querprüfung
-- Beispiel: Hohe Kreditsumme bei niedrigem Einkommen
SELECT *
FROM credit_risk_clean
WHERE loan_percent_income > 0.6;
-- Dies stellt keinen Datenfehler dar,
-- sondern eine hohe Kreditbelastung im Verhältnis zum Einkommen.
-- Solche Profile sind potenziell kritisch
-- und bilden eine wichtige Grundlage für spätere Hochrisiko-Segmente.

-- Duplicate-Kontrolle: identische Datensätze
SELECT
    COUNT(*)                           AS gesamt_anzahl,
    COUNT(DISTINCT
        CONCAT_WS('|',
            person_age,
            person_income,
            person_home_ownership,
            person_emp_length,
            loan_intent,
            loan_grade,
            loan_amnt,
            loan_int_rate,
            loan_status,
            loan_percent_income,
            cb_person_default_on_file,
            cb_person_cred_hist_length
        )
    )                                  AS eindeutige_anzahl  -- 32581- 	32416 = 165 
FROM credit_risk_clean;
-- Es wurden 165 vollständig identische Datensätze identifiziert.
-- Die Duplikate wurden bewusst nicht entfernt,
-- da sie keinen inhaltlichen Einfluss auf die Risikoanalyse haben.

-- Vollständig identische Datensätze identifizieren
SELECT
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    COUNT(*) AS anzahl
FROM credit_risk_clean
GROUP BY
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length
HAVING COUNT(*) > 1;
-- Duplikate wurden identifiziert, jedoch bewusst nicht entfernt,
-- da sie die Analyse nicht verzerren und keinen zusätzlichen Informationsgewinn liefern.


-- Ansatz 2 – Flag instead of delete
-- Nicht löschen, sondern kennzeichnen.
SELECT *,
    CASE
        WHEN loan_int_rate IS NULL THEN 1
        ELSE 0
    END AS flag_missing_int_rate
FROM credit_risk_clean;
-- Fehlende Werte wurden nicht entfernt,
-- sondern bewusst als eigenständige Information gekennzeichnet.
-- Extreme Alterswerte stellen keinen Datenfehler dar
-- und wurden daher nicht gelöscht.
-- Stattdessen erfolgte eine gezielte Kennzeichnung (Flag),
-- um diese Werte kontrolliert in die Risikoanalyse einzubeziehen.

SELECT
    *,
    CASE
        WHEN person_age < 30 THEN 'young'
        WHEN person_age BETWEEN 30 AND 45 THEN 'mid_age'
        WHEN person_age BETWEEN 46 AND 60 THEN 'upper_mid_age'
        WHEN person_age BETWEEN 61 AND 75 THEN 'senior'
        ELSE 'very_senior'
    END AS age_group,

    CASE
        WHEN person_age >= 90 THEN 1
        ELSE 0
    END AS extreme_age_flag
FROM credit_risk_clean;
-- Das Alter wurde in sinnvolle Gruppen unterteilt.
-- Alterswerte ab 90 Jahren wurden mit einem separaten Risikoflag gekennzeichnet.
-- Es wurden keine Datensätze aus dem Datenbestand gelöscht.

-- Die eigentliche Bereinigung erfolgt implizit im Feature Engineering
-- und nicht durch harte Filter.

-- ************************************** 🧩 FAZ 3 – Feature Engineering **********************************************

-- Phase 3 übersetzt Rohdaten in bankfachlich interpretierbare Merkmale
-- und bildet die Grundlage für alle späteren Risikoentscheidungen.
-- In dieser Phase erfolgt ausschließlich Feature Engineering,
-- gebündelt in einer zentralen VIEW.
-- Die Risikoanalyse in Phase 4 greift ausschließlich auf diese VIEW zurück.

-- Phase 3.1 – Zentrale finanzielle Kennzahl (Numerische Logik)
-- Loan-to-Income Ratio
-- Fragestellung: „Ist die Kredithöhe im Verhältnis zum Einkommen plausibel?“
-- Definition: Verhältnis zwischen Kreditsumme und Jahreseinkommen
-- loan_amnt / person_income AS loan_to_income_ratio
/*
📌 Interpretationslogik (zunächst als Annahme):
- 0,1  → plausibel / akzeptabel
- ≥ 0,4 → rote Flagge (hohes Risikosignal)

In dieser Phase wird ausschließlich der Kennwert berechnet.
Es erfolgt noch keine Entscheidung, sondern lediglich die Erzeugung eines Risikosignals.

Interpretationslogik (vorerst nur zur Erzeugung):
- 0,1 → plausibel
- 0,4 und höher → rote Flagge
*/

-- 2  Income Bucket (Einkommenssegmentierung)
-- Einteilung der Kreditnehmer in Einkommensgruppen,
-- um die wirtschaftliche Leistungsfähigkeit besser bewerten zu können.
/*
CASE
    WHEN person_income < 30000 THEN 'niedrig'
    WHEN person_income BETWEEN 30000 AND 70000 THEN 'mittel'
    ELSE 'hoch'
END AS einkommensgruppe

*/
-- Durch die Segmentierung des Einkommens werden Kreditnehmer
-- mit vergleichbarer finanzieller Ausgangslage gruppiert.
-- Die verwendeten Grenzwerte orientieren sich an der Verteilung im Datensatz
-- und ermöglichen eine realistische Differenzierung.

-- Phase 3.2 – Beschäftigungsstabilität & Kredithistorie
-- Ziel ist die Kategorisierung der Beschäftigungsdauer
-- als Indikator für Einkommens- und Beschäftigungsstabilität.
/*
CASE
    WHEN person_emp_length IS NULL THEN 'unbekannt'
    WHEN person_emp_length < 2 THEN 'kurz'
    WHEN person_emp_length BETWEEN 2 AND 5 THEN 'mittel'
    ELSE 'lang'
END AS beschaeftigungsstabilitaet
*/
-- Beschäftigungsdauer = Indikator für Einkommenskontinuität
-- kurz → risikosteigernd
-- lang → risikomindernd

-- 4 Kredithistorie (Credit History Bucket)
-- Einteilung der Länge der Kredithistorie
-- zur Bewertung der finanziellen Erfahrung des Kreditnehmers.
/*
CASE
    WHEN cb_person_cred_hist_length < 3 THEN 'sehr_kurz'
    WHEN cb_person_cred_hist_length BETWEEN 3 AND 7 THEN 'kurz'
    WHEN cb_person_cred_hist_length BETWEEN 8 AND 15 THEN 'mittel'
    ELSE 'lang'
END AS kredithistorie
*/
-- Kurze Kredithistorie → höhere Unsicherheit
-- Lange Kredithistorie → besser vorhersagbares Zahlungsverhalten

-- 5 Frühere Zahlungsausfälle (Previous Default Flag)
-- Binäre Variable zur Abbildung früherer Zahlungsausfälle.
-- Bestehende Information wird als sauberes Feature aufbereitet.
/*
CASE
    WHEN cb_person_default_on_file = 'Y' THEN 1
    ELSE 0
END AS frueherer_zahlungsausfall
*/
-- Frühere Zahlungsausfälle erhöhen das Risiko deutlich
-- und zählen in Phase 4 zu den stärksten Risikosignalen.

-- Phase 3.3 – Kreditbezogene Merkmale
-- 6 Zinssatz-Kategorie (Interest Rate Bucket)
-- Erhalten risikoreiche Kreditnehmer tatsächlich höhere Zinssätze?
-- Überprüfung, ob das Kredit-Pricing risikosensitiv gestaltet ist.
/*
CASE
    WHEN loan_int_rate IS NULL THEN 'unbekannt'
    WHEN loan_int_rate < 8 THEN 'niedrig'
    WHEN loan_int_rate BETWEEN 8 AND 15 THEN 'mittel'
    ELSE 'hoch'
END AS zinssatz_kategorie
*/
-- Diese Variable adressiert direkt die zentrale Managementfrage,
-- ob das Pricing angemessen auf das Kreditrisiko reagiert.

-- 7 Kreditbelastung (Loan Burden Bucket)
-- Anteil der Kreditsumme am jährlichen Einkommen.
/*
CASE
    WHEN loan_percent_income < 0.1 THEN 'gering'
    WHEN loan_percent_income BETWEEN 0.1 AND 0.25 THEN 'mittel'
    ELSE 'hoch'
END AS kreditbelastung
*/
-- Wenn ein großer Teil des Einkommens für den Kredit aufgewendet wird,
-- sinkt die finanzielle Nachhaltigkeit.
-- Diese Variable wird in Phase 4 als Risikosignal genutzt.

-- FAZ 3.4 – Zentrale Feature-Engineering View
CREATE OR REPLACE VIEW v_credit_risk_enhanced AS
SELECT
    *,
    loan_amnt / person_income AS loan_to_income_ratio,

    CASE
        WHEN person_income < 30000 THEN 'niedrig'
        WHEN person_income BETWEEN 30000 AND 70000 THEN 'mittel'
        ELSE 'hoch'
    END AS einkommensgruppe,

    CASE
        WHEN person_emp_length IS NULL THEN 'unbekannt'
        WHEN person_emp_length < 2 THEN 'kurz'
        WHEN person_emp_length BETWEEN 2 AND 5 THEN 'mittel'
        ELSE 'lang'
    END AS beschaeftigungsstabilitaet,

    CASE
        WHEN cb_person_cred_hist_length < 3 THEN 'sehr_kurz'
        WHEN cb_person_cred_hist_length BETWEEN 3 AND 7 THEN 'kurz'
        WHEN cb_person_cred_hist_length BETWEEN 8 AND 15 THEN 'mittel'
        ELSE 'lang'
    END AS kredithistorie,

    CASE
        WHEN cb_person_default_on_file = 'Y' THEN 1
        ELSE 0
    END AS frueherer_zahlungsausfall,

    CASE
        WHEN loan_int_rate IS NULL THEN 'unbekannt'
        WHEN loan_int_rate < 8 THEN 'niedrig'
        WHEN loan_int_rate BETWEEN 8 AND 15 THEN 'mittel'
        ELSE 'hoch'
    END AS zinssatz_kategorie,

    CASE
        WHEN loan_percent_income < 0.1 THEN 'gering'
        WHEN loan_percent_income BETWEEN 0.1 AND 0.25 THEN 'mittel'
        ELSE 'hoch'
    END AS kreditbelastung
FROM credit_risk_clean;

SELECT COUNT(*) FROM v_credit_risk_enhanced ;

-- In Phase 3 wurden Rohdaten in bankfachlich aussagekräftige,
-- standardisierte und wiederverwendbare Risikosignale überführt.


-- ************************************************** -- 📊 Phase 4 – Analyse der Risikofaktoren (Deep Dive) *********************************************************** 

-- Zentrale Fragestellung: Welche Faktoren erhöhen das Ausfallrisiko?
-- Risikodefinition: loan_status = 1 (Default).
-- Ziel ist die Identifikation von Kunden- und Kreditmerkmalen,
-- die die Ausfallwahrscheinlichkeit signifikant erhöhen,
-- anhand klarer Vergleiche und Ursache-Wirkungs-Logik.


-- 1.1 Einkommensgruppen bilden und Default-Statistiken berechnen
-- Steigt die Ausfallquote mit sinkendem Einkommen?
-- Ziel ist es, Risikounterschiede zwischen Einkommensgruppen sichtbar zu machen.
SELECT
    income_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN person_income < 30000 THEN 'low'
            WHEN person_income BETWEEN 30000 AND 70000 THEN 'mid'
            ELSE 'high'
        END AS income_group
    FROM v_credit_risk_enhanced
) t
GROUP BY income_group
ORDER BY default_quote_prozent DESC;
-- low     3669   1727   %47.07                    -- Mit sinkendem Einkommensniveau steigt die Default-Quote systematisch an.
-- mid     18391  4212   %22.90						-- Besonders in der Low-Income-Gruppe ist das Ausfallrisiko deutlich erhöht.
-- high    10521  1169   %11.11						-- Das Einkommen ist damit ein zentraler Faktor der Risikobewertung.


-- 2 Loan Amount × Default
-- Erhöht sich die Default-Quote mit steigender Kreditsumme?

SELECT
    loan_amount_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN loan_amnt < 5000 THEN 'low'
            WHEN loan_amnt BETWEEN 5000 AND 15000 THEN 'mid'
            ELSE 'high'
        END AS loan_amount_group
    FROM v_credit_risk_enhanced
) t																			
GROUP BY loan_amount_group																
ORDER BY default_quote_prozent DESC;								 
-- high		4929	1594	%32.34				-- Mit steigender Kreditsumme nimmt die Default-Quote zu.
-- low		7446	1547	%20.78 				-- Die Kredithöhe wirkt risikosteigernd, erklärt Ausfälle jedoch nicht isoliert.		
-- mid		20206	3967	%19.63				-- Das Verhältnis zum Einkommen (loan_percent_income) liefert ein deutlich stärkeres Risikosignal.

-- 2.1 Loan Percent Income × Default
-- Steigt das Default-Risiko mit zunehmendem Verhältnis der Kreditsumme zum Einkommen?
-- Analyse des Risikoeffekts der Kreditbelastung relativ zum Einkommen des Kreditnehmers

-- 2.1.1 Gruppenbildung nach loan_percent_income und Default-Analyse
SELECT
    loan_income_ratio_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN loan_percent_income < 0.15 THEN 'low'
            WHEN loan_percent_income BETWEEN 0.15 AND 0.35 THEN 'mid'
            ELSE 'high'
        END AS loan_income_ratio_group
    FROM v_credit_risk_enhanced
) t
GROUP BY loan_income_ratio_group
ORDER BY default_quote_prozent DESC;
-- high    2176   1565   %71.92        -- Mit steigendem Verhältnis der Kreditsumme zum Einkommen nimmt die Default-Quote deutlich zu.
-- low     15934  1933   %12.13		-- Entscheidend ist nicht die absolute Kredithöhe, sondern die Tragfähigkeit des Kredits im Verhältnis zum Einkommen.
-- mid     14471  3610   %24.95


SELECT
    loan_income_ratio_group,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_pct,
    SUM(loan_amnt) AS total_loan_volume,       									              -- Gesamtes Kreditvolumen
    SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END) AS total_loss_amount,			  -- Tatsächlich eingetretener Verlust (nur Defaults)
    ROUND(
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
        / SUM(loan_status = 1),
        2
    ) AS avg_loss_per_default,																 -- Durchschnittlicher Verlust pro ausgefallenem Kredit  
    ROUND(
    SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
    / SUM(loan_amnt),
    4
) AS loss_rate
FROM (
    SELECT *,
        CASE
            WHEN loan_percent_income < 0.15 THEN 'low'
            WHEN loan_percent_income BETWEEN 0.15 AND 0.35 THEN 'mid'
            ELSE 'high'
        END AS loan_income_ratio_group
    FROM v_credit_risk_enhanced
) t
GROUP BY loan_income_ratio_group
ORDER BY total_loss_amount DESC;
-- High Risk: Sehr hohe Default-Quote (71,9 %), aber begrenztes Kreditvolumen. Der absolute Verlust liegt bei ca. 25 Mio.
-- Mid Risk: Moderate Default-Quote (24,9 %), jedoch der höchste Gesamtverlust (~41 Mio). Kritischste Gruppe für die Bank.
-- Low Risk: Niedrige Default-Quote (12,1 %) und vergleichsweise geringer Verlust (~11 Mio).
-- Das größte finanzielle Risiko für die Bank liegt nicht im High-Risk-Segment, sondern im Mid-Risk-Segment.
-- Kreditüberwachung und Pricing sollten hier priorisiert werden.

-- Loan Percent Income (10% bins) × Default
-- Slide: "Die Gefahr der Kreditbelastung"

SELECT
    loan_load_bucket,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN loan_percent_income < 0.10 THEN '10%'
            WHEN loan_percent_income < 0.20 THEN '20%'
            WHEN loan_percent_income < 0.30 THEN '30%'
            WHEN loan_percent_income < 0.40 THEN '40%'
            WHEN loan_percent_income < 0.50 THEN '50%'
            ELSE '60%+'
        END AS loan_load_bucket
    FROM v_credit_risk_enhanced
) t
GROUP BY loan_load_bucket
ORDER BY
    CASE loan_load_bucket
        WHEN '10%' THEN 1
        WHEN '20%' THEN 2
        WHEN '30%' THEN 3
        WHEN '40%' THEN 4
        WHEN '50%' THEN 5
        ELSE 6
    END;

/*
10%		8951	1033	11.54
20%		12528	1846	14.73
30%		6817	1424	20.89
40%		2950	1822	61.76
50%		999		725		72.57
60%+	336		258		76.79
*/



-- 3️ Loan Grade × Default
-- Steigt die Ausfallquote, wenn sich die Kreditnote (loan_grade) verschlechtert?
-- Analyse, wie gut das bestehende Kreditbewertungssystem das tatsächliche Ausfallrisiko widerspiegelt

-- 3.1 Default-Analyse nach Kreditnote (Loan Grade)
SELECT
    loan_grade,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_credit_risk_enhanced
GROUP BY loan_grade
ORDER BY loan_grade;
/*
A	10777	1073	%9.96					-- Mit der Verschlechterung des Loan Grades steigt die Default-Quote deutlich an.
B	10451	1701	%16.28					-- Ab Bonitätsklasse D zeigt sich ein starker Anstieg des Ausfallrisikos.
C	6458	1339	%20.73					-- Die Grades F und G fallen nahezu vollständig aus.
D	3626	2141	%59.05					-- Das Bonitätsrating differenziert das Kreditrisiko sehr klar.
E	964		621		%64.42					-- Die Grades D bis G eignen sich für die Kreditüberwachung als Hochrisikosegmente
F	241		170		%70.54.
G	64		63		%98.44
*/


-- 4️ Credit History × Default
-- Sinkt das Ausfallrisiko, je länger die Kredithistorie ist?
--  Analyse des Einflusses der Länge der Kredithistorie
-- (cb_person_cred_hist_length) auf das Ausfallrisiko

-- 4.1 Gruppierung nach Länge der Kredithistorie
--     und Analyse der Ausfallquote
SELECT
    cred_hist_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN cb_person_cred_hist_length < 3 THEN 'short'
            WHEN cb_person_cred_hist_length BETWEEN 3 AND 7 THEN 'mid'
            ELSE 'long'
        END AS cred_hist_group
    FROM v_credit_risk_enhanced
) t
GROUP BY cred_hist_group
ORDER BY default_quote_prozent DESC;				-- Kreditnehmer mit kurzer Kredithistorie weisen eine leicht erhöhte Default-Quote auf.
-- short	5965	1406	%23.57					-- Mit zunehmender Kredithistorie sinkt das Ausfallrisiko moderat.
-- mid		17507	3799	%21.70					-- Die Unterschiede zwischen den Gruppen sind insgesamt begrenzt.
-- long		9109	1903	%20.89					-- Die Kredithistorie ist ein unterstützender, jedoch kein allein stark trennender Risikofaktor.
													-- In Kombination mit weiteren Merkmalen gewinnt sie an Aussagekraft.
                                                    
-- 5️ Frühere Defaults × Neuer Default
-- Sind Kreditnehmer, die in der Vergangenheit Zahlungsausfälle hatten, hinsichtlich eines erneuten Ausfalls risikoreicher?
-- Analyse des Einflusses früherer Zahlungsausfälle
-- (cb_person_default_on_file) auf das zukünftige Ausfallrisiko												

-- 5.1 Analyse der Ausfallquote nach früherem Default-Status
SELECT
    cb_person_default_on_file AS previous_default,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_ausfaelle,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS ausfallquote_prozent
FROM v_credit_risk_enhanced
GROUP BY cb_person_default_on_file
ORDER BY ausfallquote_prozent DESC;
-- Y   5745   2172   37.81 %        -- Kreditnehmer mit früheren Zahlungsausfällen weisen eine deutlich höhere Default-Quote auf als Kunden ohne Zahlungshistorie.
-- N   26836  4936   18.39 %		-- Frühere Zahlungsausfälle gehören zu den stärksten Risikofaktoren für zukünftige Kreditausfälle.
									-- Dieser Faktor sollte in der Kreditüberwachung besonders stark gewichtet werden.


-- 6️ Age × Default
-- Wie verändert sich das Ausfallrisiko zwischen verschiedenen Altersgruppen?
--  Analyse des Einflusses des Alters auf das Ausfallrisiko nicht linear, sondern entlang verschiedener Lebensphasen

-- 6.1 Analyse der Ausfallquote nach Altersgruppen
SELECT
    age_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN person_age < 25 THEN '<25'
            WHEN person_age BETWEEN 25 AND 40 THEN '25-40'
            WHEN person_age BETWEEN 41 AND 60 THEN '40-60'
            ELSE '60+'
        END AS age_group
    FROM v_credit_risk_enhanced
) t
GROUP BY age_group
ORDER BY default_quote_prozent DESC;
-- 60+		70		17		%24.29			-- Die Default-Quote unterscheidet sich zwischen den Altersgruppen moderat.
-- <25	 	12315	2860	%23.22			-- Die niedrigste Ausfallquote zeigt sich im Alter von 25 bis 40 Jahren, 
-- 40-60	1424	302		%21.21			-- während sehr junge (<25) und ältere Kreditnehmer (60+) höhere Risiken aufweisen.
-- 25-40	18772	3929	%20.93          -- Das Alter wirkt nicht linear auf das Ausfallrisiko, sondern zeigt ein leicht U-förmiges Risikomuster.


-- 7️ Home Ownership × Default
-- Beeinflusst die Wohnsituation das Ausfallrisiko?
-- Analyse von Risikounterschieden in Abhängigkeit vom Eigentumsstatus


SELECT
    person_home_ownership,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_credit_risk_enhanced
GROUP BY person_home_ownership
ORDER BY default_quote_prozent DESC;                  -- Kreditnehmer mit Mietverhältnis (RENT) oder sonstiger Wohnform (OTHER)
-- RENT			16446	5192	%31.57				  -- weisen deutlich höhere Default-Quoten auf als Eigentümer.
-- OTHER		107		33		%30.84				  -- Die niedrigste Ausfallquote zeigt sich bei Kreditnehmern mit Wohneigentum (OWN).
-- MORTGAGE		13444	1690	%12.57				  -- Die Wohnsituation ist ein starker Indikator für finanzielle Stabilität.
-- OWN			2584	193		%7.47				  -- Wohneigentum korreliert klar mit einem geringeren Ausfallrisiko.

-- 8️ Employment Length × Default
-- Sinkt das Ausfallrisiko mit zunehmender Beschäftigungsdauer?
-- Analyse des Einflusses der Dauer der Beschäftigung
-- (person_emp_length) auf das Ausfallrisiko

-- 8.1 Gruppierung nach Beschäftigungsdauer
--     und Analyse der Ausfallquote
SELECT
    emp_length_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN person_emp_length IS NULL THEN 'unknown'
            WHEN person_emp_length < 2 THEN 'short'
            WHEN person_emp_length BETWEEN 2 AND 5 THEN 'mid'
            ELSE 'long'
        END AS emp_length_group
    FROM v_credit_risk_enhanced
) t
GROUP BY emp_length_group
ORDER BY default_quote_prozent DESC;				-- Mit zunehmender Beschäftigungsdauer sinkt die Default-Quote kontinuierlich.
-- unknown		895		282		%31.51				-- Kreditnehmer mit kurzer oder unbekannter Beschäftigungshistorie weisen deutlich höhere Ausfallrisiken auf.
-- short		7020	1953	%27.82				-- Die Beschäftigungsdauer ist ein starker Indikator für finanzielle Stabilität.
-- mid			13125	2841	%21.65				-- Kurze oder unbekannte Beschäftigung signalisiert ein erhöhtes Ausfallrisiko.
-- long			11541	2032	%17.61


-- 9️ Loan Intent × Default
-- Beeinflusst der Verwendungszweck des Kredits (loan_intent) das Ausfallrisiko?
-- Analyse von Risikounterschieden zwischen verschiedenen Kreditverwendungszwecken

SELECT
    loan_intent,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_credit_risk_enhanced
GROUP BY loan_intent
ORDER BY default_quote_prozent DESC;

-- DEBTCONSOLIDATION	5212	1490	%28.59     -- Die Default-Quote unterscheidet sich deutlich nach dem Kreditverwendungszweck.
-- MEDICAL				6071	1621	%26.70     -- Besonders DEBTCONSOLIDATION weist die höchste Ausfallquote auf, gefolgt von MEDICAL und HOMEIMPROVEMENT.
-- HOMEIMPROVEMENT		3605	941		%26.10	   -- EDUCATION und VENTURE zeigen die niedrigsten Ausfallquoten.
-- PERSONAL				5521	1098	519.89     -- Der Kreditverwendungszweck ist ein relevanter Risikofaktor,
-- EDUCATION			6453	1111	%17.22	   -- insbesondere bei Schuldenkonsolidierung und schwer planbaren Ausgaben.
-- VENTURE				5719	847		%14.81

-- 10 Loan Interest Rate × Default
-- Fragestellung: Steigt das Ausfallrisiko mit zunehmendem Zinssatz?
-- Ziel: Funktioniert risikobasiertes Pricing in der Praxis?

-- 10.1 Analyse der Default-Quote nach Zinssatzgruppen
SELECT
    int_rate_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN loan_int_rate < 8 THEN 'low'
            WHEN loan_int_rate BETWEEN 8 AND 15 THEN 'mid'
            ELSE 'high'
        END AS int_rate_group
    FROM v_credit_risk_enhanced
    WHERE loan_int_rate IS NOT NULL
) t
GROUP BY int_rate_group
ORDER BY default_quote_prozent DESC;    		 -- Mit zunehmendem Zinssatz steigt die Default-Quote sehr deutlich an.
-- high		3441	1996	%58.01       		 -- Kredite mit hohem Zinssatz weisen ein extrem hohes Ausfallrisiko auf,
-- mid		18254	3738	%20.48			     -- während Kredite mit niedrigem Zinssatz nur geringe Ausfälle zeigen.
-- low		7770	730		%9.40                -- Der Zinssatz spiegelt das tatsächliche Kreditrisiko sehr gut wider.
												 -- Das Pricing folgt klar einem risikobasierten Ansatz.

-- 📊 FAZ 4 – Risikofaktorenanalyse | Abschlusszusammenfassung

-- Ziel dieser Phase:
-- Identifikation zentraler Faktoren, die mit dem Kreditausfallrisiko
-- (loan_status = 1) zusammenhängen.

-- Zentrale Erkenntnisse:
-- 1) Einkommen:
-- Niedrige Einkommen gehen mit signifikant höheren Default-Quoten einher.
-- 2) Kredithöhe vs. Tragfähigkeit:
-- Die absolute Kreditsumme ist nur begrenzt aussagekräftig.
-- Der stärkste Zusammenhang zeigt sich beim Verhältnis von Kredit zu Einkommen
-- (loan_percent_income).
-- 3) Loan Grade:
-- Das Bonitätsrating differenziert das Risiko sehr klar.
-- Ab Loan Grade D steigt die Default-Quote stark an;
-- die Grades D bis G stellen Hochrisikosegmente dar.
-- 4) Kredithistorie:
-- Die Länge der Kredithistorie wirkt unterstützend,
-- jedoch mit moderater Trennschärfe.
-- 5) Frühere Zahlungsausfälle:
-- Frühere Defaults gehören zu den stärksten Prädiktoren
-- zukünftiger Kreditausfälle.
-- 6) Alter:
-- Das Ausfallrisiko folgt keinem linearen Muster.
-- Junge (<25) und ältere (60+) Kreditnehmer weisen höhere Risiken auf
-- als Kunden im mittleren Erwerbsalter.
-- 7) Wohnsituation:
-- Wohneigentum korreliert klar mit geringeren Ausfallquoten,
-- während Mieter höhere Risiken aufweisen.
-- 8) Beschäftigungsdauer:
-- Mit zunehmender Beschäftigungsdauer sinkt das Ausfallrisiko kontinuierlich.
-- 9) Kreditverwendungszweck:
-- Schuldenkonsolidierung und schwer planbare Ausgaben
-- sind mit höheren Default-Quoten verbunden.
-- 10) Zinssatz:
-- Der Zinssatz spiegelt das tatsächliche Ausfallrisiko sehr gut wider
-- und bestätigt einen funktionierenden risk-based-pricing Ansatz.
-- Gesamtfazit:
-- Das Kreditausfallrisiko ergibt sich aus dem Zusammenspiel von
-- Einkommenssituation, finanzieller Tragfähigkeit,
-- Bonitätsbewertung und vergangenem Zahlungsverhalten.
-- Ausblick FAZ 5:
-- Diese Risikofaktoren bilden die Grundlage für die Segmentierung
-- der Kreditnehmer in Risiko-Gruppen (niedrig / mittel / hoch).

-- ************************************** Phase 5 – Kreditüberwachung (Aufgabe 1 ) **********************************************************************************

-- Phase 5.1 – Risikoindikatoren & analytische Grundlage
-- Ziel dieses Schritts ist es, jene Variablen zu identifizieren,
-- die tatsächlich in einem belastbaren Zusammenhang
-- mit dem Kreditausfallrisiko stehen.
-- In dieser Phase werden die in FAZ 1–3 vorbereiteten Daten genutzt,
-- ohne bestehende Daten zu verändern.
-- Es erfolgt ausschließlich eine transparente Analyse
-- der Beziehung zwischen Variablen und Ausfallrisiko.
-- Die Risikosegmentierung basiert damit nicht auf
-- willkürlichen Regeln, sondern auf datengetriebenen Erkenntnissen.
-- Zentrale Risikoindikatoren:
-- loan_grade
-- loan_percent_income
-- person_income
-- person_emp_length
-- cb_person_default_on_file
-- loan_status (zur Validierung)


-- SCHRITT 5.1.1 – Zusammenhang zwischen Risiko und Ausfall
-- Analytische Fragestellung: Steigt die Ausfallquote mit zunehmendem Risiko?

-- FAZ 5.1.1 – Ausfallquote nach Bonitätsklasse (loan_grade)
SELECT
    loan_grade,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_default,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_credit_risk_enhanced
GROUP BY loan_grade
ORDER BY loan_grade;
-- A	10777	1073	%9.96            -- Die Ausfallquote steigt von Bonitätsklasse A bis G kontinuierlich an.
-- B	10451	1701	%16.28   	     -- Ab Klasse D zeigt sich ein deutlicher Risikoanstieg, Klasse G weist nahezu vollständige Ausfälle auf.
-- C	6458	1339	%20.73  		 -- loan_grade ist ein äußerst starker und konsistenter Indikator zur Erklärung des Kreditrisikos.
-- D	3626	2141	%59.05    			-- Die Bonitätsklassen D bis G bilden den zentralen Risikobereich und eignen sich besonders für Frühwarnsysteme sowie gezielte Maßnahmen zur Verlustminimierung.
-- E	964		621		%64.42
-- F	241		170		%70.54
-- G	64		63		%98.44
-- Phasenentscheidung FAZ 5.1.1:
-- loan_grade ist geeignet für die Risikosegmentierung
-- und eine zentrale Komponente der High / Medium / Low Klassifizierung.


-- SCHRITT 5.1.2 – Zusammenhang zwischen Einkommensbelastung und Risiko Analytische Fragestellung:
-- Erhöht eine hohe Kreditbelastung im Verhältnis zum Einkommen das Ausfallrisiko?

-- 5.1.2 – Segmentanalyse der Kreditbelastung (loan_percent_income)
SELECT
    CASE
        WHEN loan_percent_income < 0.1 THEN 'niedrig'
        WHEN loan_percent_income BETWEEN 0.1 AND 0.3 THEN 'mittel'
        ELSE 'hoch'
    END AS einkommensbelastung,
    COUNT(*) AS anzahl_kredite,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_credit_risk_enhanced
GROUP BY einkommensbelastung;
/*
hoch	3834	%70.32
mittel	19796	%17.07
niedrig	8951	%11.54
*/
-- Mit zunehmender Kreditbelastung (loan_percent_income) steigt die Default-Quote stark an.
-- In der Gruppe mit hoher Einkommensbelastung liegt die Ausfallquote bei über 70 %.
-- Der Zusammenhang zeigt ein klares Schwellenverhalten und verläuft nicht linear.

-- Eine im Verhältnis zum Einkommen überhöhte Kreditbelastung
-- gehört zu den stärksten Treibern des Kreditausfallrisikos.
-- Kredite mit hoher Einkommensbelastung sollten
-- im Kreditüberwachungsprozess priorisiert werden.
-- Verbindung zu Phase 5.1.1:
-- Das Ergebnis bestätigt die Bedeutung des loan_grade
-- und zeigt, dass Kreditrisiko zusätzlich
-- über die finanzielle Tragfähigkeit erklärbar ist.
-- Die Kombination aus schlechter Bonität
-- und hoher Einkommensbelastung definiert
-- das risikoreichste Kreditnehmerprofil.
-- Phasenentscheidung Phase 5.1.2:
-- loan_percent_income ist ein zentrales Kriterium der High-Risk-Definition.
-- Phasenentscheidung FAZ 5.1.2:
-- loan_percent_income ist ein zentrales Kriterium
-- für die Definition von Hochrisiko-Kreditnehmern.
-- Die verwendeten Grenzwerte sind datenbasiert abgeleitet.

--  5.1.3 – Beschäftigungsstabilität & Risiko
--  5.1.3 – Ausfallquote nach Beschäftigungsdauer
SELECT
    CASE
        WHEN person_emp_length IS NULL THEN 'unbekannt'
        WHEN person_emp_length < 2 THEN 'kurz'
        WHEN person_emp_length BETWEEN 2 AND 5 THEN 'mittel'
        ELSE 'lang'
    END AS beschaeftigungsdauer,
    COUNT(*) AS anzahl_kredite,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS ausfallquote_prozent
FROM v_credit_risk_enhanced
GROUP BY beschaeftigungsdauer;
-- kurz / unbekannt → risikosteigernd                   -- Mit abnehmender Beschäftigungsdauer steigt die Default-Quote systematisch an.
-- lang → risikomindernd								-- Die Reihenfolge lang → mittel → kurz → unbekannt zeigt einen klaren,  monotonen Anstieg des Risikos.
-- lang        11541   17.61 %  						-- Besonders Kreditnehmer mit unbekannter Beschäftigungsdauer weisen die höchste Unsicherheit und Ausfallquote auf.
-- mittel      13125   21.65 %							-- Die Beschäftigungsstabilität steht in direktem Zusammenhang
-- kurz        7020    27.82 %							-- mit dem Rückzahlungsverhalten und ist ein relevanter Risikofaktor.
-- unbekannt   895     31.51 %

-- FAZ 5.2 – Risikomerkmale & Grenzwerte (Regelableitung)

-- Ziel:
-- Ableitung klarer, erklärbarer Regeln zur Einteilung
-- von Kreditnehmern in Low / Medium / High Risk.
-- In diesem Schritt erfolgen keine neuen Analysen
-- und kein Feature Engineering,
-- sondern die regelbasierte Nutzung der Ergebnisse aus FAZ 5.1.
-- Zentrales Prinzip:
-- Nicht ein einzelnes Signal,
-- sondern die Kombination mehrerer Risikofaktoren
-- definiert das tatsächliche Kreditrisiko.
-- Bestätigte Risikotreiber:
-- loan_grade D–G
-- hohe Einkommensbelastung (loan_percent_income)
-- kurze oder unbekannte Beschäftigungsdauer
-- frühere Zahlungsausfälle
-- Risikomindernde Faktoren:
-- loan_grade A–B
-- niedrige Einkommensbelastung
-- lange Beschäftigungsdauer
-- keine Zahlungshistorie
--
-- Abgeleitete Grenzwerte:
-- loan_grade:   Low = A,B | Medium = C | High = D–G
-- loan_percent_income: niedrig < 0.10 | mittel 0.10–0.30 | hoch > 0.30
-- person_emp_length:   lang > 5 | mittel 2–5 | kurz < 2 | unbekannt = NULL
-- cb_person_default_on_file: yes = starker Risikofaktor

-- Risikosegmentierungslogik:
-- High Risk:
-- Kombination aus schlechter Bonität,
-- hoher Einkommensbelastung
-- oder früheren Zahlungsausfällen.
-- Medium Risk:
-- Solide Bonität mit einzelnen Warnsignalen,
-- beobachtungswürdig.
-- Low Risk:
-- Gute Bonität, geringe Belastung,
-- stabile Beschäftigung, keine Zahlungsausfälle.

-- 5.2.4 – Risikosegmentierung mit SQL (ERSTE VERSION)
-- Diese erste Version wird im nächsten Schritt gemeinsam überprüft und bei Bedarf angepasst.
-- FAZ 5.2 – Risikosegmentierung (High / Medium / Low)
SELECT
    *,
    CASE
        -- 🔴 HIGH RISK
        WHEN loan_grade IN ('D','E','F','G')
             OR loan_percent_income > 0.30
             OR cb_person_default_on_file = 'Y'
             OR (person_emp_length < 2 OR person_emp_length IS NULL)
                AND loan_grade IN ('C','D','E','F','G')
        THEN 'High Risk'

        -- 🟡 MEDIUM RISK
        WHEN loan_grade = 'C'
             OR (loan_grade = 'B' AND loan_percent_income BETWEEN 0.10 AND 0.30)
             OR person_emp_length BETWEEN 2 AND 5
        THEN 'Medium Risk'

        -- 🟢 LOW RISK
        ELSE 'Low Risk'
    END AS risiko_segment
FROM v_credit_risk_enhanced;

-- FAZ 5.2.5 – Operative Überwachungssegmentierung 
-- Ziel: Ableitung der Überwachungsintensität für die kreditnehmerbezogene Kreditüberwachung.
CREATE OR REPLACE VIEW v_monitoring_segments AS
SELECT
    *,
    CASE
        -- 🔴 HIGH MONITORING
        WHEN loan_grade IN ('D','E','F','G')
             OR loan_percent_income > 0.30
             OR cb_person_default_on_file = 'Y'
             OR ((person_emp_length < 2 OR person_emp_length IS NULL)
                 AND loan_grade IN ('C','D','E','F','G'))
        THEN 'High Risk'

        -- 🟡 MEDIUM MONITORING
        WHEN loan_grade = 'C'
             OR (loan_grade = 'B' AND loan_percent_income BETWEEN 0.10 AND 0.30)
             OR person_emp_length BETWEEN 2 AND 5
        THEN 'Medium Risk'

        -- 🟢 LOW MONITORING
        ELSE 'Low Risk'
    END AS risk_segment
FROM v_credit_risk_enhanced;


SELECT
    risk_segment,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        loan_status,
        CASE
            -- 🔴 HIGH RISK
            WHEN loan_grade IN ('D','E','F','G')
                 OR loan_percent_income > 0.30
                 OR cb_person_default_on_file = 'Y'
                 OR (person_emp_length < 2 OR person_emp_length IS NULL)
                    AND loan_grade IN ('C','D','E','F','G')
            THEN 'High Risk'

            -- 🟡 MEDIUM RISK
            WHEN loan_grade = 'C'
                 OR (loan_grade = 'B' AND loan_percent_income BETWEEN 0.10 AND 0.30)
                 OR person_emp_length BETWEEN 2 AND 5
            THEN 'Medium Risk'

            -- 🟢 LOW RISK
            ELSE 'Low Risk'
        END AS risk_segment
    FROM v_credit_risk_enhanced
) t
GROUP BY risk_segment
ORDER BY default_quote_prozent DESC;

-- High Risk	11562	5530	47.83   -- An dieser Stelle wird bewusst pausiert,  um eine Plausibilitäts- und Angemessenheitsprüfung durchzuführen.
-- Medium Risk	13247	1097	8.28    -- Ist die Logik bankfachlich nachvollziehbar?
-- Low Risk 	7772	481		6.19    -- Ist die High-Risk-Definition möglicherweise zu breit gefasst?
-- Reicht loan_percent_income > 0.30 als alleiniges Kriterium aus?

-- FAZ 5.3 – Validierung & Balance-Check der Risikosegmente
-- Ziel ist die Überprüfung, ob die Segmentierung sinnvoll, ausgewogen und praxistauglich ist.

-- 5.3.1 – Segmentbasierte Verteilung (Wie viele Kreditnehmer pro Segment?)
-- 5.3.1 – Anzahl der Kreditnehmer & prozentualer Anteil

SELECT
    risk_segment,
    COUNT(*) AS anzahl_kredite,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM v_credit_risk_enhanced) * 100, 2) AS anteil_prozent
FROM (
    SELECT
        CASE
            WHEN loan_grade IN ('D','E','F','G')
                 OR loan_percent_income > 0.30
                 OR cb_person_default_on_file = 'Y'
                 OR (person_emp_length < 2 OR person_emp_length IS NULL)
                    AND loan_grade IN ('C','D','E','F','G')
            THEN 'High Risk'

            WHEN loan_grade = 'C'
                 OR (loan_grade = 'B' AND loan_percent_income BETWEEN 0.10 AND 0.30)
                 OR person_emp_length BETWEEN 2 AND 5
            THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS risk_segment
    FROM v_credit_risk_enhanced
) t
GROUP BY risk_segment; 
-- High Risk    11562   35.49 %       -- Ein zu hoher High-Risk-Anteil deutet auf eine zu konservative Einstufung hin,  ein zu hoher Low-Risk-Anteil auf eine Unterschätzung des Risikos.
-- Medium Risk  13247   40.66 %	 	  -- Ideal ist eine Segmentverteilung mit einem dominanten Medium-Risk-Segment und ausgewogenem Anteil von High und Low Risk.
-- Low Risk     7772    23.85 % 
-- Die Kreditnehmer verteilen sich sinnvoll auf alle Segmente.
-- Medium Risk stellt das größte Segment dar und zeigt eine gesunde Verteilung.
-- High Risk ist weder zu klein noch zu groß,
-- sodass Risiken erkannt werden und die Bank handlungsfähig bleibt.
-- Low Risk ist ausreichend groß,
-- um den operativen Überwachungsaufwand zu reduzieren.

-- ≈ 35 % High Risk:  Fokus intensiver Überwachungsmaßnahmen
-- ≈ 41 % Medium Risk: Standardüberwachung mit Trendbeobachtung
-- ≈ 24 % Low Risk: reduzierte Überwachung zur Kostensenkung
-- Überwachungsressourcen können gezielt, effizient und risikoadäquat eingesetzt werden.

-- 5.3.2 – Segment Bazlı Default Oranı 
-- FAZ 5.3.2 – Default-Quote je Risikosegment
SELECT
    risk_segment,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_default,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM (
    SELECT
        *,
        CASE
            WHEN loan_grade IN ('D','E','F','G')
                 OR loan_percent_income > 0.30
                 OR cb_person_default_on_file = 'Y'
                 OR (person_emp_length < 2 OR person_emp_length IS NULL)
                    AND loan_grade IN ('C','D','E','F','G')
            THEN 'High Risk'

            WHEN loan_grade = 'C'
                 OR (loan_grade = 'B' AND loan_percent_income BETWEEN 0.10 AND 0.30)
                 OR person_emp_length BETWEEN 2 AND 5
            THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS risk_segment
    FROM v_credit_risk_enhanced
) t
GROUP BY risk_segment;
-- Erwartetes Ergebnis 
-- High Risk → höchste Ausfallquote ✔
-- Medium Risk: → mittlere Ausfallquote ✔
-- Low Risk: → niedrigste Ausfallquote ✔
--  Ist diese Trennung klar erkennbar, gilt die Risikosegmentierung als erfolgreich.

-- High Risk    11562   5530   47.83 %
-- Medium Risk  13247   1097    8.28 %
-- Low Risk      7772    481    6.19 %

-- Analytische Bewertung (kritischer Kern)
-- Im High-Risk-Segment:
-- Fast jeder zweite Kredit fällt aus.
-- Es besteht eine sehr starke und eindeutige Risikotrennung.

-- Medium Risk:
-- Die Ausfallquote sinkt deutlich.
-- Das Risikoniveau ist kontrollierbar.

-- Low Risk:
-- Niedrigste Ausfallquote.
-- Erwartungsgemäß die sicherste Gruppe.

-- Unterschiede zwischen den Segmenten:
-- High vs. Medium → ca. 6-fach
-- High vs. Low → ca. 8-fach
-- Dies belegt eine sehr hohe Trennschärfe der Risikosegmentierung.

-- High Risk (47,8 % Ausfall): → intensive, häufige und proaktive Überwachung erforderlich.
-- Medium Risk (8,3 %): → Standardüberwachung mit Trendbeobachtung ausreichend.
-- Low Risk (6,2 %): → reduzierte Überwachung, Potenzial zur Senkung operativer Kosten.
-- Fazit: Ein risikobasierter Kreditüberwachungsansatz ist operativ sinnvoll und zwingend erforderlich.


-- Management-Level-Botschaft (Aufgabe 1 abgeschlossen):
-- Die Ergebnisse zeigen eine klare Trennung der Ausfallwahrscheinlichkeiten
-- zwischen den Risikosegmenten.
-- Eine differenzierte Kreditüberwachung ermöglicht
-- eine gezielte Ressourcennutzung
-- bei gleichzeitiger Reduktion operativer Kosten.


-- **************************** Phase 6 Risikogruppen & Grenzwert (Aufgabe 2)  ************************************************************************************

-- Ziel dieser Phase:
-- Einteilung der Kreditnehmer in Low / Medium / High Risk
-- auf Basis datengetriebener und bankfachlich erklärbarer Regeln.
-- Die Grenzwerte leiten sich aus den Ergebnissen der vorherigen Phasen ab
-- (EDA, Datenqualität, Feature Engineering)
-- und wurden nicht willkürlich festgelegt.
-- Kreditrisiko wird als multidimensionales Konzept verstanden:
-- Erst die Kombination mehrerer Faktoren erlaubt
-- eine realistische Risikobewertung.

-- 🧱 1️ ZENTRALE RISIKOKLASSIFIKATION (SYSTEM GRUNDLAGE)
-- Einmal definieren – überall verwenden
-- FAZ 6.0 – Finale Risikoklassifikation (Worst-Case, AND-basiert)

CREATE OR REPLACE VIEW v_final_risk_classification AS
SELECT
    *,
    CASE
        -- 🔴 HIGH RISK (Worst Case):
        -- Hohe Einkommensbelastung + schwache Bonität + frühere Ausfälle
        WHEN loan_percent_income > 0.40
             AND loan_grade IN ('E','F','G')
             AND cb_person_default_on_file = 'Y'
        THEN 'High Risk'
        -- 🟡 MEDIUM RISK:
        -- Teilweise Risikosignale vorhanden
        WHEN loan_percent_income BETWEEN 0.25 AND 0.40
             OR loan_grade IN ('C','D')
        THEN 'Medium Risk'
        -- 🟢 LOW RISK:
        -- Gute Bonität, geringe Belastung, keine früheren Ausfälle
        WHEN loan_percent_income < 0.25
             AND loan_grade IN ('A','B')
             AND cb_person_default_on_file = 'N'
        THEN 'Low Risk'
        -- Fallback
        ELSE 'Medium Risk'
    END AS risk_group
FROM v_credit_risk_enhanced;

-- 2️ KONTROL 1 – Verteilung der Risikogruppen (Balance Check)
-- Kontrolle der Risikoverteilung
-- Ziel: Überprüfung der Ausgewogenheit der Klassifizierung

SELECT
    risk_group,
    COUNT(*) AS anzahl_kreditnehmer,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM v_final_risk_classification) * 100, 2) AS anteil_prozent
FROM v_final_risk_classification
GROUP BY risk_group;
-- Medium Risk   15515   47.62 %
-- Low Risk      17030   52.27 %
-- High Risk        36    0.11 %

-- Interpretation:
-- Medium Risk stellt das zentrale Segment dar.
-- Low Risk ist stark vertreten.
-- High Risk ist bewusst sehr klein definiert.
-- Fazit:
-- Die Klassifizierung ist ausgewogen,
-- jedoch klar konservativ ausgelegt.

-- 3 KONTROLLE 2 – Trennschärfe (Default-Quote je Segment)
-- Validierung der Risikosegmente
-- Ziel: Überprüfung der Trennschärfe

SELECT
    risk_group,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_final_risk_classification
GROUP BY risk_group
ORDER BY default_quote_prozent DESC;
-- High Risk     36     30     83.33 %
-- Medium Risk   15515  6002   38.69 %
-- Low Risk      17030  1076    6.32 %


SELECT
    loan_grade,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_default,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_final_risk_classification
GROUP BY loan_grade
ORDER BY loan_grade;

-- Ergebnis:
-- Die Default-Quoten unterscheiden sich sehr deutlich.
-- Fazit:
-- Die Risikoklassifikation ist analytisch valide
-- und trennt das Kreditrisiko effektiv.
-- Empfehlung:
-- Die High-Risk-Definition ist sehr präzise,
-- jedoch möglicherweise zu restriktiv.
-- Der operative Fokus sollte auf dem Medium-Risk-Segment liegen,
-- da hier das größte absolute Ausfallpotenzial besteht.

-- 6.1 Operative Risikoklassifizierung (Erweiterung) 
-- Ziel dieser Phase:
-- Einführung einer zweiten, praxisorientierten Risikoschicht. 
-- Während Phase 6.0 das "Worst-Case" Szenario (0.11% High Risk) isoliert, 
-- adressiert Phase 6.1 die operative Realität der Bank.

-- Warum eine zweite Klassifizierung?
-- Die Analyse der Phase 6.0 zeigte eine Default-Quote von fast 39% im Medium-Risk-Segment. 
-- Dies signalisiert, dass signifikante Risiken im Medium-Bereich "versteckt" sind.
-- Durch Phase 6.1 werden diese Risiken durch eine intelligentere OR-Logik 
-- in die High-Risk-Klasse überführt, um eine präzisere Überwachung zu ermöglichen.
-- 🧱 1️ OPERATIVE RISIKOKLASSIFIKATION (V2)
-- Einteilung mit Fokus auf Portfoliosteuerung und Monitoring-Kapazitäten.
CREATE OR REPLACE VIEW v_operational_risk_classification AS
SELECT
    *,
    CASE
        -- 🔴 OPERATIONAL HIGH RISK
        -- Bankanın günlük izleme ve pricing için kullanacağı grup
        WHEN
            (loan_percent_income > 0.35 AND loan_grade IN ('D','E','F','G'))
            OR (cb_person_default_on_file = 'Y' AND loan_percent_income > 0.30)
        THEN 'High Risk'

        -- 🟡 MEDIUM RISK
        WHEN
            loan_percent_income BETWEEN 0.20 AND 0.35
            OR loan_grade IN ('C','D')
        THEN 'Medium Risk'

        -- 🟢 LOW RISK
        WHEN
            loan_percent_income < 0.20
            AND loan_grade IN ('A','B')
            AND cb_person_default_on_file = 'N'
        THEN 'Low Risk'

        ELSE 'Medium Risk'
    END AS risk_group
FROM v_credit_risk_enhanced;
-- 2️ KONTROLLE 1 – Verteilung der operativen Risikogruppen
-- Ziel: Sicherstellung der "Balance" gemäß Projektaufgabe.
SELECT 
    risk_group,
    COUNT(*) AS anzahl_kreditnehmer,
    ROUND(COUNT(*) / (SELECT 
                    COUNT(*)
                FROM
                    v_operational_risk_classification) * 100,
            2) AS anteil_prozent
FROM
    v_operational_risk_classification
GROUP BY risk_group
ORDER BY anzahl_kreditnehmer DESC;
-- Medium Risk	17080	%52.42
-- Low Risk		14534	%44.61
-- High Risk	967		%2.97

-- Ergebnis (Check): 
-- High Risk steigt von 0.11% auf ca. 3%, was operativ deutlich relevanter ist.

-- 3 KONTROLLE 2 – Trennschärfe-Validierung (Default-Quote)
-- Ziel: Beweis, dass die neue Logik Risiken besser trennt.
SELECT
    risk_group,
    COUNT(*) AS anzahl_kreditnehmer,
    SUM(loan_status = 1) AS anzahl_defaults,
    ROUND(
        SUM(loan_status = 1) / COUNT(*) * 100,
        2
    ) AS default_quote_prozent
FROM v_operational_risk_classification
GROUP BY risk_group
ORDER BY default_quote_prozent DESC;
-- High Risk		967		763		%78.90
-- Medium Risk		17080	5494	%32.17
-- Low Risk			14534	851		%5.86
-- Interpretation der Ergebnisse:
-- 1. High Risk (78.90% Default): Extrem präzise Identifikation von Ausfallkandidaten.
-- 2. Medium Risk (32.17% Default): Deutliche Reduktion der Ausfallrate im Vergleich zu V1.
-- 3. Low Risk (5.86% Default): Sehr stabiles und sicheres Segment.
--
-- Fazit:
-- Diese Klassifizierung ist das "Herzstück" der operativen Steuerung. 
-- Sie bietet die optimale Balance zwischen Risiko-Sensitivität und bankpraktischer Anwendbarkeit.

SELECT
    loan_grade,
    COUNT(*) AS anzahl_kredite,
    SUM(loan_status = 1) AS anzahl_default,
    ROUND(SUM(loan_status = 1) / COUNT(*) * 100, 2) AS default_quote_prozent
FROM v_operational_risk_classification
GROUP BY loan_grade
ORDER BY loan_grade;

-- FAZ 6.2 – Ergänzende Frühwarnlogik (Management Alerts)
-- Separater Layer – kein Einfluss auf die finale Risikoklasse

-- FAZ 6.2 – Ergänzende Frühwarnlogik (OR-basiert)
-- Ziel: Management-Alerts, keine finale Risikoklassifikation

CREATE OR REPLACE VIEW v_manager_alerts AS
SELECT
    *,
    CASE
        WHEN loan_percent_income > 0.40
            THEN 'Alert: Very High Income Burden'
        WHEN loan_grade IN ('E','F','G')
             AND loan_int_rate < 10
            THEN 'Alert: Risky Grade but Low Interest'
        WHEN cb_person_default_on_file = 'Y'
             AND loan_amnt > 15000
            THEN 'Alert: Previous Default & High Loan Amount'
        WHEN (person_emp_length < 2 OR person_emp_length IS NULL)
             AND loan_grade IN ('C','D','E','F','G')
            THEN 'Alert: Low Employment Stability'
        ELSE 'No Alert'
    END AS manager_alert
FROM v_operational_risk_classification;

-- 4 AUSWERTUNG DER FRÜHWARNLOGIK
SELECT
    manager_alert,
    COUNT(*) AS anzahl,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM v_operational_risk_classification) * 100, 2) AS anteil_prozent
FROM v_manager_alerts
GROUP BY manager_alert;
-- Alert: Very High Income Burden            1120    3.44
-- No Alert                                  27874   85.55
-- Alert: Previous Default & High Loan Amount 974    2.99
-- Alert: Low Employment Stability            2612   8.02
-- Alert: Risky Grade but Low Interest           1   0.00

SELECT COUNT(*) AS anzahl_der_warnungen
FROM v_manager_alerts
WHERE manager_alert <> 'No Alert';       -- 4707

-- Fazit:
-- Die Frühwarnlogik ist weder zu restriktiv noch zu großzügig.
-- Sie ergänzt die konservative Risikoklassifikation sinnvoll,
-- ohne diese zu verfälschen.
-- Architekturprinzip:
-- Erst stabiles Risikosystem (FAZ 6),
-- dann ergänzende Frühwarnsignale (FAZ 6.2).


-- ************************* 📈 FAZ 7 – Ergebnisse & Business Implications (GÜNCEL) *************************
-- „Welchen konkreten Mehrwert liefert diese Analyse für die Bank?“
--
-- Diese Analyse versetzt die Bank in die Lage, ihr Kreditportfolio nicht mehr nur statisch zu betrachten,
-- sondern durch ein hybrides Modell aus Risiko-Klassifizierung und Frühwarn-Logik aktiv zu steuern.
-- Der Mehrwert ergibt sich aus der Verknüpfung von drei Sicherheitsebenen:

-- 1. Strategische Ebene: Konservative Klassifikation (Faz 6.0)
-- Identifikation der absolut kritischen "Worst-Case" Fälle (Extreme High Risk).
-- Ergebnis: 
-- • Identifikation von 0,11 % des Portfolios mit extrem hoher Ausfallwahrscheinlichkeit (83%).
-- Business Implication: 
-- Diese Gruppe dient der Identifikation von Totalausfällen, bei denen sofortige rechtliche Schritte 
-- oder eine vollständige Abschreibung geprüft werden müssen. [cite: 161, 162]

-- 2. Operative Ebene: Praxisorientierte Klassifikation (Faz 6.1)
-- Dies ist das Herzstück der neuen Portfoliosteuerung. Hier wurde die Balance zwischen Risiko und Ertrag optimiert.
-- Ergebnis:
-- • Steigerung der High-Risk-Erkennung von 0,11 % auf ca. 3 % des Portfolios.
-- • Präzision: Die neue High-Risk-Gruppe weist eine Default-Quote von ca. 79 % auf!
-- Business Implication:
-- Diese Ebene ermöglicht ein zielgerichtetes "Intensive Care" Monitoring. Bankressourcen werden nicht 
-- verschwendet, sondern punktgenau dort eingesetzt, wo die Daten einen massiven Ausfall prognostizieren. [cite: 42, 43]

-- 3. Überwachungsebene: Management Alerts & Frühwarnsystem (Faz 6.2)
-- Ein dynamischer Layer, der Anomalien im Vergabeprozess aufdeckt. [cite: 46]
-- Ergebnis:
-- • Rund 14,5 % des Portfolios werden durch spezifische Warnsignale markiert.
-- • Identifikation von Fehl-Bepreisungen (z.B. Risky Grade but Low Interest). [cite: 47, 48]
-- Business Implication:
-- Proaktive Steuerung statt reaktiver Schadensbegrenzung. Der Vorstand kann gezielt prüfen, 
-- ob Kundenbetreuer gegen Pricing-Richtlinien verstoßen haben. [cite: 50]

-- 4. Effizienzsteigerung und Kostensenkung
-- Durch die neue "Low Risk" Definition (Default-Quote nur ca. 6 %) kann der manuelle Prüfaufwand 
-- für fast 45 % des Portfolios signifikant reduziert werden.
-- Ergebnis:
-- ✔ Massives Einsparpotenzial bei den operativen Prozesskosten. [cite: 40]
-- ✔ Fokus der Risikoanalysten auf die kritischen 3 % (High) und 52 % (Medium).

-- 5. Fazit & Management-Empfehlung (FINAL)
-- Das entwickelte Modell erfüllt die Forderung nach einer "kreditnehmerspezifischen Kreditüberwachung". [cite: 42]
-- Empfehlung:
-- 1. Implementierung der operativen Klassifikation (Faz 6.1) als Standard-Reporting-Tool. [cite: 161]
-- 2. Nutzung der Management-Alerts zur regelmäßigen Revision der Kreditvergabeprozesse. [cite: 162]
-- 3. Anpassung der Zinskonditionen basierend auf den identifizierten "Loan Percent Income" Schwellenwerten. [cite: 94]

-- Diese Analyse liefert eine belastbare, datengetriebene Grundlage, um Kreditausfälle zu minimieren 
-- und die Profitabilität des Kreditgeschäfts nachhaltig zu sichern. 



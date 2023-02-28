CREATE OR REPLACE PROCEDURE PROCEDURE2 AS
BEGIN
DBMS_OUTPUT.PUT_LINE('HOLA MUNDO');
END PROCEDURE2;

CREATE OR REPLACE PROCEDURE PROCEDURE3 (n in varchar) AS
BEGIN
DBMS_OUTPUT.PUT_LINE('HOLA '|| n);
END PROCEDURE3;

CREATE OR REPLACE PROCEDURE PROCEDURE4 AS
max_cantidad distribucion.cantidad%TYPE;
BEGIN
SELECT max(cantidad) INTO max_cantidad
FROM distribucion;

DBMS_OUTPUT.PUT_LINE('La cantidad maxima es: '|| max_cantidad);

END PROCEDURE4;

CREATE OR REPLACE PROCEDURE PROCEDURE5(conc in concesionarios.cifc%TYPE) AS
c distribucion.cantidad%TYPE;
BEGIN
SELECT SUM(cantidad) INTO c
FROM distribucion
WHERE distribucion.cifc = conc;
DBMS_OUTPUT.PUT_LINE('El concesionario '||conc|| ' contiene '||c|| ' coches');
END PROCEDURE5;

CREATE TABLE totales (
    ntventas NUMBER, ntcoches NUMBER, ntmarcas NUMBER, ntclientes NUMBER, 
    ntconcesionarios NUMBER)

CREATE OR REPLACE PROCEDURE PROCEDURE6 AS
nv NUMBER;
nc NUMBER;
nm NUMBER;
ncli NUMBER;
ncon NUMBER;
BEGIN
SELECT COUNT(*) INTO nv FROM VENTAS;
SELECT COUNT(*) INTO nc FROM COCHES;
SELECT COUNT(*) INTO nm FROM MARCAS;
SELECT COUNT(*) INTO ncli FROM CLIENTES;
SELECT COUNT(*) INTO ncon FROM CONCESIONARIOS;
INSERT INTO totales VALUES (nv,nc,nm,ncli,ncon);
COMMIT;
END PROCEDURE6;

CREATE TABLE HistoricoClientes(
     dni varchar2(9) PRIMARY KEY, nombre varchar2(40), apellido varchar2(40),
     ciudad varchar2(40));

CREATE OR REPLACE PROCEDURE PROCEDURE7_1 AS

BEGIN
INSERT INTO historicoClientes SELECT * FROM CLIENTES;
COMMIT;
END PROCEDURE7_1;

CREATE OR REPLACE PROCEDURE PROCEDURE7_2 AS
CURSOR listaClientes is SELECT * FROM  CLIENTES;
uncliente listaClientes%ROWTYPE;
BEGIN
    open listaClientes;
    fetch listaClientes INTO uncliente;
    while listaClientes%found LOOP
        BEGIN
            INSERT INTO historicoClientes VALUES(uncliente.dni, uncliente.nombre, uncliente.apellido, uncliente.ciudad);
        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE historicoclientes
            SET nombre = uncliente.nombre, apellido = uncliente.apellido, ciudad = uncliente.ciudad
            WHERE dni = uncliente.dni;
        END;
    fetch listaClientes INTO uncliente;
    END LOOP;
    close listaClientes;
    COMMIT;    
END PROCEDURE7_2;


CREATE OR REPLACE PROCEDURE PROCEDURE8_1 AS

BEGIN
FOR o IN (SELECT object_name, object_type FROM USER_OBJECTS) LOOP
        DBMS_OUTPUT.PUT_LINE('Objeto: '||o.object_name||' Tipo: '||o.object_type);
    END LOOP;
END PROCEDURE8_1;

CREATE OR REPLACE PROCEDURE PROCEDURE8_2 AS
CURSOR objeto is (SELECT object_name, object_type FROM USER_OBJECTS);
nombreObjeto USER_OBJECTS.object_name%TYPE;
tipoObjeto USER_OBJECTS.object_type%TYPE;
BEGIN
OPEN objeto;
LOOP
    FETCH objeto INTO nombreObjeto, tipoObjeto;
    EXIT WHEN objeto%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Objeto: ' || nombreObjeto|| ' Tipo ' || tipoObjeto);
END LOOP;
CLOSE objeto;
END PROCEDURE8_2;


SELECT cl.dni, cl.nombre, cl.apellido, count(*)
FROM Clientes cl, ventas v
WHERE cl.dni = v.dni
GROUP BY cl.dni, cl.nombre, cl.apellido;

CREATE TABLE COMPRAS(
    dni varchar2(9), nombre varchar2(40), apellido varchar2(40), ncoches NUMBER);

CREATE OR REPLACE PROCEDURE PROCEDURE9_1 AS
BEGIN
    INSERT INTO compras
    SELECT cl.dni, cl.nombre, cl.apellido, count(*) as numcoches
    FROM Clientes cl, ventas v
    WHERE cl.dni = v.dni
    GROUP BY cl.dni, cl.nombre, cl.apellido;
    COMMIT;
END PROCEDURE9_1;

CREATE OR REPLACE PROCEDURE PROCEDURE9_2 AS
CURSOR cochesporcliente IS 
    SELECT cl.dni, cl.nombre, cl.apellido, count(*) as numcoches
    FROM Clientes cl, ventas v
    WHERE cl.dni = v.dni
    GROUP BY cl.dni, cl.nombre, cl.apellido;
uncliente cochesporcliente%ROWTYPE;
BEGIN
    OPEN cochesporcliente;
    FETCH cochesporcliente INTO uncliente;
    while cochesporcliente%FOUND LOOP
        INSERT INTO COMPRAS values(uncliente.dni, uncliente.nombre, uncliente.apellido, uncliente.numcoches);
        FETCH cochesporcliente INTO uncliente;
    END LOOP;
    COMMIT;
    CLOSE cochesporcliente;
END PROCEDURE9_2;


CREATE OR REPLACE PROCEDURE PROCEDURE10 (conc in concesionarios.cifc%TYPE, nv OUT number) AS
BEGIN
    SELECT count(*) into nv
    FROM VENTAS 
    WHERE cifc = conc;
END PROCEDURE10;

CREATE OR REPLACE FUNCTION FUNCION10 (conc in concesionarios.cifc%TYPE) RETURN NUMBER AS
nv number;
BEGIN
    SELECT count(*) into nv
    FROM VENTAS 
    WHERE cifc = conc;
    RETURN nv;
END FUNCION10;

CREATE OR REPLACE FUNCTION FUNCION11 (ciud clientes.ciudad%TYPE) RETURN NUMBER AS
nc NUMBER;
BEGIN
    SELECT COUNT(*) into nc
    FROM Clientes
    WHERE ciudad = ciud;
    return nc;
END FUNCION11;

CREATE OR REPLACE PROCEDURE PROCEDURE11(ciud in clientes.ciudad%TYPE, nc OUT number) AS
BEGIN
    SELECT COUNT(*) into nc
    FROM Clientes
    WHERE ciudad = ciud;
END PROCEDURE11;

CREATE OR REPLACE PROCEDURE LISTARCOCHESPORCLIENTE AS 
    CURSOR CLIENTES IS 
        SELECT DISTINCT nombre, apellido,cl.dni, sum(v.codcoche)as numcoches, sum(v.cifc)as numconc
        FROM CLIENTES cl, VENTAS v
        WHERE cl.dni = v.dni
        GROUP BY nombre, apellido, cl.dni;
    CURSOR COCHES (dnic ventas.dni%TYPE ) IS
        SELECT c.codcoche, c.nombrech, c.modelo, v.color
        FROM COCHES c, Ventas v
        WHERE c.codcoche = v.codcoche AND v.dni = dnic;
BEGIN
    FOR cli IN clientes LOOP
        DBMS_OUTPUT.PUT_LINE('- Cliente: '||cli.nombre||' '||cli.apellido||' '||cli.numcoches||' '||cli.numconc);
        FOR coc IN COCHES(cli.dni) LOOP
            DBMS_OUTPUT.PUT_LINE('---> Coche: '||coc.codcoche||' '||coc.nombrech||' '||coc.modelo||' '||coc.color);
        END LOOP;
    END LOOP;
END LISTARCOCHESPORCLIENTE;


CREATE OR REPLACE PROCEDURE LISTARCOCHESUNCLIENTE(dnic in clientes.dni%TYPE) AS
    CURSOR COCHES IS
        SELECT c.codcoche, c.nombrech, c.modelo, v.color
        FROM coches c, ventas v
        WHERE c.codcoche = v.codcoche AND v.dni = dnic;
        numcoches NUMBER;
        numconc NUMBER;
        cli clientes%ROWTYPE;
BEGIN
    SELECT * into cli 
    from clientes WHERE
    dni = dnic;

    SELECT COUNT(*), COUNT (DISTINCT CIFC) into numcoches, numconc
    FROM ventas 
    WHERE dni = dnic;

    DBMS_OUTPUT.PUT_LINE('- Cliente: '||cli.nombre||' '||cli.apellido||' '||numcoches||' '||numconc);
    FOR coc in coches LOOP
        DBMS_OUTPUT.PUT_LINE('---> Coche: '||coc.codcoche||' '||coc.nombrech||' '||coc.modelo||' '||coc.color);
    END LOOP;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Datos incorrectos del cliente');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error' || sqlcode||' '||sqlerrm);
END LISTARCOCHESUNCLIENTE;
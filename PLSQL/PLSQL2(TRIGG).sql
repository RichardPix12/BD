ALTER TABLE compras ADD DatosMayus varchar2(100);

CREATE OR REPLACE TRIGGER MantenDatosMayus
    BEFORE INSERT OR UPDATE OF NOMBRE, APELLIDO ON COMPRAS
    FOR EACH ROW
BEGIN
    :NEW.datosmayus:=UPPER(CONCAT(:NEW.nombre,:NEW.apellido));
END;




CREATE OR REPLACE TRIGGER IncrementaCompras
    AFTER INSERT ON VENTAS
    FOR EACH ROW
DECLARE
    n NUMBER;
    nom clientes.nombre%TYPE;
    ape clientes.apellido%TYPE;
BEGIN
    SELECT COUNT(*) into n
    FROM   compras
    WHERE dni =:NEW.dni;
    
    IF n=0 THEN
        SELECT nombre, apellido into nom, ape
        FROM clientes
        WHERE dni=:NEW.dni;
        INSERT INTO compras VALUES(:NEW.dni,nom,ape,1,NULL);
    ELSE
        UPDATE compras SET ncoches = ncoches+1 WHERE dni=:NEW.dni;
    END IF;
END;






CREATE OR REPLACE TRIGGER IncrementaComprasVentas
    AFTER INSERT OR DELETE ON VENTAS
    FOR EACH ROW
DECLARE
    n NUMBER;
    nom clientes.nombre%TYPE;
    ape clientes.apellido%TYPE;
BEGIN
    IF inserting THEN
        SELECT COUNT(*) into n
        FROM   compras
        WHERE dni =:NEW.dni;
        
        IF n=0 THEN
            SELECT nombre, apellido into nom, ape
            FROM clientes
            WHERE dni=:NEW.dni;
            INSERT INTO compras VALUES(:NEW.dni,nom,ape,1,NULL);
        ELSE
            UPDATE compras SET ncoches = ncoches WHERE dni=:NEW.dni;
        END IF;
    END IF;
    
    IF deleting THEN
        SELECT COUNT(*) INTO n
        FROM compras
        WHERE dni=:OLD.dni;
        IF n=0 THEN
            DELETE 
            FROM compras
            WHERE dni=:OLD.dni;
        ELSE
            UPDATE compras SET ncoches = ncoches-1 WHERE dni=:OLD.dni;
        END IF;
    END IF;   
END;

CREATE TABLE AUDITORIA_CLIENTES(
    dniant varchar2(9),
    Nombreant varchar2(40),
    Apellidoant varchar2(40),
    Ciudadant varchar2(40),
    dniact varchar2(9),
    Nombreact varchar2(40),
    Apellidoact varchar2(40),
    Ciudadact varchar2(40),
    Fechahora date
);

CREATE OR REPLACE TRIGGER MantenAuditoriaClientes
    AFTER INSERT OR DELETE OR UPDATE ON Clientes
    FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO AUDITORIA_CLIENTES VALUES(null,null,null,null,:NEW.dni,:NEW.nombre,:NEW.apellido,:NEW.ciudad,sysdate);
    ELSIF deleting THEN
        INSERT INTO AUDITORIA_CLIENTES VALUES(:OLD.dni,:OLD.nombre,:OLD.apellido,:OLD.ciudad,null,null,null,null,sysdate);
    ELSE
        INSERT INTO AUDITORIA_CLIENTES VALUES(:OLD.dni,:OLD.nombre,:OLD.apellido,:OLD.ciudad,:NEW.dni,:NEW.nombre,:NEW.apellido,:NEW.ciudad,sysdate);
    END IF;
END;


CREATE OR REPLACE TRIGGER DisminuyeCoches
    AFTER INSERT ON VENTAS
    FOR EACH ROW
DECLARE
    n distribucion.cantidad%TYPE;
BEGIN
    SELECT cantidad INTO n
    FROM distribucion
    WHERE cifc =:NEW.cifc and codcoche =:NEW.codcoche;
    
    IF n>=1 THEN
        UPDATE distribucion SET cantidad=cantidad-1 WHERE cifc=:NEW.cifc and codcoche =:NEW.codcoche;
    ELSE
        Raise_application_error(-20001,'No quedan coches de tipo '|| :NEW.codcoche || ' En el concesionario '|| :NEW.cifc);
    END IF;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Raise_application_error(-20002,'No se han encontrado ese tipo de coches en el concesionario');
    WHEN OTHERS THEN
        Raise_application_error(-20003,sqlcode||' '||sqlerrm);
END;

CREATE TABLE AUDITA_COMPRAS(
operacion VARCHAR2(20),
fecha DATE,
usuario VARCHAR2(20));

CREATE TRIGGER AUDITANDO_COMPRAS
    AFTER INSERT OR DELETE OR UPDATE ON COMPRAS
    FOR EACH ROW
DECLARE
    us VARCHAR2(20);
BEGIN
    us:=sys_context('USERENV','CURRENT_USER');
    IF inserting THEN
        INSERT INTO AUDITA_COMPRAS VALUES('Insertando',sysdate,us);
    ELSIF deleting THEN
        INSERT INTO AUDITA_COMPRAS VALUES('Borrando',sysdate,us);
    ELSE
        INSERT INTO AUDITA_COMPRAS VALUES('Actualizando',sysdate,us);
    END IF;  
END;

CREATE TRIGGER NoMasCochesAmarillos
    BEFORE INSERT OR UPDATE OF color ON VENTAS
    FOR EACH ROW
BEGIN
    IF :NEW.color = 'Amarillo' THEN
    Raise_application_error(-20001, 'El color amarillo ya no existe');
    END IF;
END;

CREATE OR REPLACE TRIGGER LimiteCoches
    BEFORE INSERT ON Distribucion
    FOR EACH ROW
DECLARE
    numcoc distribucion.cantidad%TYPE;
    stock distribucion.cantidad%TYPE;
BEGIN
    SELECT sum(cantidad) into numcoc
    from distribucion
    WHERE cifc =:NEW.cifc;
    
    IF numcoc IS NULL THEN
        numcoc := 1;
    END IF;
    stock := numcoc + :NEW.cantidad;
    IF stock > 40 THEN
        Raise_application_error(-20001,'El concesionario no puede albergar mas coches de este tipo');
    END IF;
END;

CREATE OR REPLACE TRIGGER CierreConcesionario
    BEFORE INSERT OR UPDATE OF CIFC ON VENTAS
    FOR EACH ROW
BEGIN
    IF :NEW.cifc = 1 THEN
        Raise_application_error(-20001,'El concesionario 1 ha cerrado');
    END IF;
END;

CREATE TABLE CONTROLAROJOS(
    cifc varchar2(255),
    nombreconc varchar2(255),
    dni varchar2(9),
    nombre varchar2(40),
    codcoche INTEGER,
    nombrech varchar2(255),
    modelo varchar2(255),
    fecha DATE
);
CREATE OR REPLACE TRIGGER SustanciaToxica
    AFTER INSERT OR UPDATE OF color ON VENTAS
    FOR EACH ROW
DECLARE
    nconc concesionarios.nombrec%TYPE;
    ncli clientes.nombre%TYPE;
    ncoche coches.nombrech%TYPE;
    modelo coches.modelo%TYPE;
BEGIN
    IF :NEW.color = 'rojo' THEN
        SELECT nombrec into nconc
        FROM concesionarios
        WHERE cifc=:NEW.cifc;

        SELECT nombre into ncli
        FROM clientes
        WHERE dni =:NEW.dni;

        SELECT nombrech, modelo INTO ncoche,modelo
        FROM coches
        WHERE codcoche =:New.codcoche;

        INSERT INTO CONTROLAROJOS VALUES(:NEW.cifc,nconc,:NEW.dni,ncli,:NEW.codcoche,ncoche,modelo,sysdate);
    END IF;

    IF UPDATING THEN
        IF :OLD.color = 'rojo' AND :NEW.color<>'rojo' THEN
            DELETE FROM CONTROLAROJOS WHERE cifc=:NEW.cifc AND dni=:NEW.dni AND codcoche=:NEW.codcoche;
        END IF;
    END IF;
END;


CREATE OR REPLACE TRIGGER PROHIBIDOGRIS
    BEFORE INSERT OR UPDATE OF COLOR ON VENTAS
    FOR EACH ROW
DECLARE
    model coches.modelo%TYPE;
BEGIN
    SELECT modelo into model
    FROM coches
    WHERE codcoche=:NEW.codcoche;
    IF :NEW.color = 'gris' THEN
        IF model = 'gtd' THEN
            :NEW.color := 'blanco';
        ELSE
            :NEW.color := 'negro';
        END IF;
    END IF;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Raise_application_error(-20003,'El coche no existe');
END;

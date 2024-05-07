![Diagrama deploy tool](./png/omnileads_logo_1.png)

## 100% Open-Source Contact Center Software

[Community Forum](https://forum.omnileads.net/)

# OMniLeads Terraform AWS

En este repositorio vamos a encontrar una receta para administrar instancias de OMniLeads en la nube de AWS usando Terraform. 
Esta fomar de gestión de OMniLeads está orientada a empresas que deseen  implementar el modelo de Software as a Service o 
bien Contact Center as a Service. 

# Migrar de 1.X a 2.X

```
cd terraform-aws
git checkout oml-dev-2.0
make init TENANT=nombre_tenant ARQ=aio DIALER=yes|no
```

Luego se debe editar el archivo 

```nombre_tenant.auto.tfvars```

con los valores de configuración correspondientes como:

```
pg_storage              = 100
rds_postgres_version    ="11.22"

upgrade_to_major        ="true"

scale_asterisk          ="true" 
scale_uwsgi             ="true" 
```

FROM ubuntu:18.04 AS base

LABEL author="MORTADA" \
      name="MYSQL SQLSERVER DB2 ORACLE POSTGRESQL Databrciks IMAGE" \
      version="v1.0-BETA"

#ADD user
RUN useradd -ms /bin/bash mortada

#Install image dependencies
RUN dpkg --add-architecture i386 && apt-get -y -qq update \
    && apt-get -y -qq install make gcc g++ \
    && apt-get install -y python3.8 python3-pip python3.8-dev \
    build-essential unixodbc-dev libpq-dev alien libaio1 curl \
    libx32stdc++6 libstdc++6 libpam0g:i386 \
    vim

# COPY DEPENDENCIES
COPY ["./config/mysql-driver/*", \
      "./config/oracle-driver/*", \
      "./config/openssl.cnf", \
      "./config/simba-spark-driver/*", \
      "./config/odbc/odbcinst.ini", \
      "/opt/"]

# INSTALL MYSQL DRIVER
RUN dpkg -i /opt/mysql-connector-odbc_8.0.21-1ubuntu18.04_amd64.deb || echo "_" \
    && dpkg -i /opt/mysql-connector-odbc-dbgsym_8.0.21-1ubuntu18.04_amd64 || echo "_" \
    && dpkg -i /opt/mysql-connector-odbc-setup_8.0.21-1ubuntu18.04_amd64.deb || echo "_" \
    && dpkg -i /opt/mysql-connector-odbc-setup-dbgsym_8.0.21-1ubuntu18.04_amd64.deb || echo "_" \
    && apt-get -fy install \
    && apt-get update \
    && apt-get -y install mysql-connector-odbc-setup

# INSTALL ORACLE DRIVER
RUN alien -i /opt/oracle-instantclient-basic-linuxx64.rpm \
    && alien -i /opt/oracle-instantclient-odbc-linuxx64.rpm

ENV LD_LIBRARY_PATH="/usr/lib/oracle/19.6/client64/lib:${LD_LIBRARY_PATH}"
ENV ORACLE_HOME="/usr/lib/oracle/19.6/client64"

RUN ldconfig \
    && /usr/lib/oracle/19.6/client64/bin/odbc_update_ini.sh / \
    && mv /opt/odbcinst.ini /usr/local/etc/odbcinst.ini

# RUN odbcinst -j
ENV NLS_LANG=".AL32UTF8"
ENV ODBCINI="/root/.odbc.ini"
ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SQLSERVER DRIVER
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install --yes msodbcsql17 \
    && ACCEPT_EULA=Y apt-get install --yes mssql-tools \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
    && cp /opt/openssl.cnf /etc/ssl/openssl.cnf

ENV PATH="/opt/mssql-tools/bin:${PATH}"

#INSTALL SIMBA SPARK DRIVER (DATABRICKS)
RUN dpkg -i /opt/simbaspark_2.6.19.1033-2_amd64.deb || echo "_" \
    && apt-get -fy install \
    && apt-get update

# NOTE: IF THERE IS ANY PACKAGE: comment the env ODBCSYSINI and RUN odbcinst -j
ENV ODBCSYSINI="/usr/local/etc"
ENV SIMBASPARKINI="/opt/simba/sparkodbc/lib/64/simba.sparkodbc.ini"

# CLEAN UP
RUN rm /opt/mysql-connector* /opt/oracle-* /opt/simbaspark_2*

WORKDIR /home/mortada

USER mortada

CMD ["/bin/bash"]

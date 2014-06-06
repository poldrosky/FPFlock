#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  pdbc.py
#  
#  Copyright 2014 Omar Ernesto Cabrera Rosero <omarcabrera@udenar.edu.co>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

import psycopg2

class DBConnector():
    def __init__(self):
        dbname = 'trajectories'
        user = 'omar'
        password = '123'
        host = 'localhost'
        port = '5432'
        try:
            self.conn = psycopg2.connect("dbname='{0}' user='{1}' password='{2}' host='{3}' port='{4}'".format(dbname, user, password, host, port))
            print("Connection OK")
        except:
            print("No connection")
    
            
    def createTableFlock(self,table):
        self.table = table
        cur = self.conn.cursor()
        create = """CREATE TABLE IF NOT EXISTS
                    {0} (fid Integer,
                    started integer,
                    ended integer,
                    members character varying); """.format(table)
        try:
            cur.execute(create)
            self.conn.commit()
        except:
            print("Error creating table")
            
    def createTableFlockLines(self,table):
        self.table = table
        cur = self.conn.cursor()
        create = """CREATE TABLE IF NOT EXISTS
                    {0} (fid Integer,
                    started integer,
                    ended integer,
                    members character varying,
                    line character varying); """.format(table)
        try:
            cur.execute(create)
            self.conn.commit()
        except:
            print("Error creating table")
        
    
    def resetTable(self,table):
        self.table = table
        cur = self.conn.cursor()
        truncate = """TRUNCATE TABLE {0};""".format(table)
                
        try:
            cur.execute(truncate)
            self.conn.commit()
        except:
            print("Error reset table")
            
    
    def createTableTest(self):
        self.table = 'test'
        cur = self.conn.cursor()
        create = """CREATE TABLE IF NOT EXISTS {0} 
                        (dataset character varying,
                        epsilon integer,
                        mu integer,
                        delta integer,
                        timetest real,
                        flocks integer,
                        tag character varying
                        ) """.format(self.table)
        
        try:
            cur.execute(create)
            self.conn.commit()
        except:
            print("Error creating test table")
                        
        
    def insertTest(self, filename, epsilon, mu, delta, time, flocks, tag):
        self.table = 'test'
        cur = self.conn.cursor()
        insert = """INSERT INTO {0} VALUES('{1}',{2},{3},{4},{5},{6},'{7}')""".format(self.table,
                                                filename, epsilon, mu, delta, time, flocks, tag)
                                                
        try:
            cur.execute(insert)
            self.conn.commit()
        except:
            print("Error insert table test")
        
            
    def copyToTable(self,table, stdin):
        self.table = table
        self.stdin = stdin
        cur = self.conn.cursor()
        try:
            cur.copy_from(stdin, table)
            self.conn.commit()
            print("Copy OK")
        except:
            print("Copy Error")
            
    def getTable(self, table):
        self.table = table
        cur = self.conn.cursor()
        try:
            cur.execute("SELECT * FROM {0}".format(table))
            rows = cur.fetchall()
            return rows
        except:
            print("TABLE ERROR")
            
    def getData(self, sql):
        self.sql = sql
        cur = self.conn.cursor()
        try:
            cur.execute(sql)
            rows = cur.fetchone()
            return rows
        except:
            print("SQL ERROR")
        

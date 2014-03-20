#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  bfev1.py
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
			print("Conection OK")
		except:
			print("No conection")
			
	def resetTable(self,table):
		self.table = table
		cur = self.conn.cursor()
		drop = """DROP TABLE IF EXISTS
				{0};""".format(table)
		create = """CREATE TABLE
					{0} (fid Integer,  started integer,  ended integer,   members character varying); """.format(table)
		try:
			cur.execute(drop)
			cur.execute(create)
			self.conn.commit()
		except:
			print("ERROR")
			
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

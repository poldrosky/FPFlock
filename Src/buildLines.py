#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  buildLines.py
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

import csv
import Pdbc
import io

db = Pdbc.DBConnector()

tableFlocks = "flocksfponline"
tableData = "oldenburg"

flocks = db.getTable(tableFlocks)

stdin = []

for flock in flocks:
    line = ""
    members = flock[3].replace('[','').replace(']','').split(',')
    for member in members:
        a, b = int(flock[1]),int(flock[2])
        x = y = 0
        while(a<=b):
            pos = db.getData("SELECT * from {0} WHERE oid = '{1}' and otime = '{2}'".format(tableData, member, a))
            x = x + pos[2]
            y = y + pos[3]
            a+=1
        centroidX = x / len(members)
        centroidY = y / len(members)
        if member != members[-1]:
            centroid = str(centroidX) +" "+ str(centroidY) + ","
        else:
            centroid = str(centroidX) +" "+ str(centroidY)
        line +=  centroid
    line = "LINESTRING ("+ line + ")"
    stdin.append('{0}\t{1}\t{2}\t{3}\t{4}'.format(flock[0],flock[1], flock[2], flock[3], line))
    
table = ('flocklines')
stdin = '\n'.join(stdin)

db.createTableFlockLines(table)
db.resetTable(table)
db.copyToTable(table,io.StringIO(stdin))


        
        
                    


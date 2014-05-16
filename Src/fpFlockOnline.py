#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  fpFlockOnline.py
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

import LCMmaximal
import time
import csv
import os
import Pdbc
import io
import sys

class FPFlock(object):
    """ This class is intanced with epsilon, mu and delta"""
    def __init__(self, epsilon, mu, delta):
        self.epsilon = epsilon
        self.mu = mu
        self.delta = delta

    def getTransactions(points, maximalDisks):
        for maximal in maximalDisks:
            for member in maximalDisks[maximal].members:
                if not member  in traj.keys():
                    traj[member]= []
                    traj[member].append(maximalDisks[maximal].id)
                else:
                    traj[member].append(maximalDisks[maximal].id)
        return traj
	
    def flocks(output1, totalMaximalDisks, keyFlock):
        lines = output1.readlines()
        for line in lines:
            lineSplit = line.split(' ')
            array = list(map(int,lineSplit[:-1]))
            array.sort()
            if len(array) < delta:
                continue
            members = totalMaximalDisks[int(str(array[0]))].members
            begin = totalMaximalDisks[int(str(array[0]))].timestamp
            end = begin
            for element in range(1,len(array)):
                now = totalMaximalDisks[int(str(array[element]))].timestamp
                if(now == end + 1 or now == end):
                    if(now == end + 1):
                        members = members.intersection(totalMaximalDisks[int(str(array[element]))].members)
                    end = now
					
                elif end-begin >= delta - 1:
                    b = list(members)
                    b.sort()
                    stdin.append('{0}\t{1}\t{2}\t{3}'.format(keyFlock, begin, end, b))
                    keyFlock += 1
                    begin = end = now

                else:
                    begin = end = now

            if end-begin >= delta - 1:
                b = list(members)
                b.sort()
                stdin.append('{0}\t{1}\t{2}\t{3}'.format(keyFlock, begin, end, b))
                keyFlock += 1
	
        return stdin
			
    def flockFinder(self,filename,tag):
        global traj
        global stdin
        global delta

        LCMmaximal.epsilon = self.epsilon
        LCMmaximal.mu = self.mu
        delta = self.delta
        LCMmaximal.precision = 0.001

        dataset = csv.reader(open('Datasets/'+filename, 'r'),delimiter='\t')

        if os.path.exists('output.dat'):
            os.system('rm output.dat')		
		
        if os.path.exists('output.mfi'):
            os.system('rm output.mfi')

        output = open('output.dat','w')
        next(dataset)

        t1 = time.time()

        points = LCMmaximal.pointTimestamp(dataset)

        timestamps = list(map(int,points.keys()))
        timestamps.sort()

        keyFlock = 1
        diskID = 1

        traj = {}
        totalMaximalDisks = {}
        stdin = []

        for timestamp in timestamps:
            LCMmaximal.disksTimestamp(points, timestamp)
            if os.path.getsize('outputDisk.dat') == 0:
                continue
            maximalDisks, diskID = LCMmaximal.maximalDisksTimestamp(timestamp, diskID)
            totalMaximalDisks.update(maximalDisks)

            FPFlock.getTransactions(points, maximalDisks)

        for i in traj:
            if len(traj[i]) == 1:
                continue
            output.write(str(traj[i])+'\n')
		
        output.close()
		
        os.system("./fim_closed output.dat " + str(LCMmaximal.mu) + " output.mfi > /dev/null")
		
        if os.path.exists('output.mfi'):
            output1 = open('output.mfi','r')				
		
            keyFlock = 1
            stdin = FPFlock.flocks(output1, totalMaximalDisks, keyFlock)
				
        table = ('flocksFP')
        print("Flocks: ",len(stdin))
        flocks = len(stdin)
        stdin = '\n'.join(stdin)
        db = Pdbc.DBConnector()
        db.createTableFlock(table)
        db.resetTable(table.format(filename))
        db.copyToTable(table,io.StringIO(stdin))
		
        t2 = round(time.time()-t1,3)
        print("\nTime: ",t2)
		
        db.createTableTest()
        db.insertTest(filename,self.epsilon,self.mu, delta, t2, flocks, tag)
		
def main():
    #fp = FPFlock(200,3,3)
    #flockFinder('SJ2500T100t500f.csv')
    #fp.flockFinder('Oldenburg.csv','fptest1')

    fp = FPFlock(int(sys.argv[1]),int(sys.argv[2]),int(sys.argv[3]))
    fp.flockFinder(str(sys.argv[4]),'fp1'+str(sys.argv[5]))
	
if __name__ == '__main__':
    main()

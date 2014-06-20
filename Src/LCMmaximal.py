#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  LCMmaximal.py
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
import scipy.spatial as ss
import math
import time
import os

class Index(object):
    def __init__(self,x,y):
        self.x = x
        self.y = y
        
    def __str__ (self):
        return "%s %s" % (self.x, self.y)    

    
class Point(object):
    def __init__(self, *args):
        if len(args) == 4:
            self.id = int(args[0])
            self.time = int(args[1])
            self.x = float(args[2])
            self.y = float(args[3])
        
        elif len(args) == 2:
            self.x = float(args[0])
            self.y = float(args[1])
        else:
            raise SomeException()
        
    def getIndex(self):
        index = Index(int(self.x/epsilon), int(self.y/epsilon))
        return index
        
    def __str__(self):
        return "%s %s" % (self.x, self.y)
    

class Grid(object):
    def __init__(self,dictPoint):
        self.dictPoint = dictPoint
        
    def getPoints(self,indexGrid):
        try:
            return self.dictPoint[str(indexGrid)]
        except:
            return []
    
    def getFrame(self, point):
        points = []
        index = point.getIndex()
        a=index.x
        b=index.y
        points += Grid.getPoints(self,Index(a,b))
        points += Grid.getPoints(self,Index(a-1,b+1))
        points += Grid.getPoints(self,Index(a,b+1))
        points += Grid.getPoints(self,Index(a+1,b+1))
        points += Grid.getPoints(self,Index(a-1,b))
        points += Grid.getPoints(self,Index(a+1,b))
        points += Grid.getPoints(self,Index(a-1,b-1))
        points += Grid.getPoints(self,Index(a,b-1))
        points += Grid.getPoints(self,Index(a+1,b-1))
                
        if (len(points) >= mu):
            return points            
        else:
            return []
        

class Disk(object):
    def __init__(self,id, timestamp,members):
        self.id = id        
        self.members = members
        self.timestamp = int(timestamp)
                
    
def calculateDisks(p1, p2):
    """Calculate the center of the disk passing through two points"""
    r2 = math.pow(epsilon/2,2)
        
    p1_x = p1.x
    p1_y = p1.y
    p2_x = p2.x
    p2_y = p2.y
    
    X = p1_x - p2_x
    Y = p1_y - p2_y
    D2 = math.pow(X, 2) + math.pow(Y, 2)
    
    if (D2 == 0):
        return []

    expression = abs(4 * (r2 / D2) - 1)
    root = math.pow(expression, 0.5)
    h_1 = ((X + Y * root) / 2) + p2_x
    h_2 = ((X - Y * root) / 2) + p2_x
    k_1 = ((Y - X * root) / 2) + p2_y
    k_2 = ((Y + X * root) / 2) + p2_y

    disk = (Point(h_1, k_1))
    #disks.append(Point(h_2, k_2))
    return disk


def pointTimestamp(dataset):
    """Receive dataset and return dictonary points per timestamp"""
    points={}
    for id, timestamp, latitude, longitude in dataset:
        if timestamp in points:
            points[timestamp].append(Point(int(id),int(timestamp),float(latitude),float(longitude)))
        else:
            points[timestamp] = []
            points[timestamp].append(Point(int(id),int(timestamp),float(latitude),float(longitude)))
    return points
    

def disksTimestamp(points, timestamp):
    """Receive points per timestamp and return center disks compare, 
    nearest tree centers and disks per timestamp with yours members"""
    dictPoint={}
        
    if os.path.exists('outputDisk.dat'):
        os.system('rm outputDisk.dat')
                
    for point in points[str(timestamp)]:
        index = point.getIndex()
        if str(index) in dictPoint:
            value = dictPoint[str(index)]
            value.append(point)
        else:
            value=[]
            value.append(point)
            dictPoint[str(index)]= value
    
    grid = Grid(dictPoint)
    centersDiskCompare=[]
    
    stdin = ''
    for point in points[str(timestamp)]:
        
        pointsFrame = grid.getFrame(point)
        
        if (pointsFrame == []):
            continue    
        
        frame = []
        
        for i in pointsFrame:
            frame.append((i.x,i.y))
            
        treeFrame = ss.cKDTree(frame)
        pointsNearestFrame = treeFrame.query_ball_point([point.x,point.y], epsilon+precision)
    
        for i in pointsNearestFrame:
            p2 = pointsFrame[i]
            if point == p2:
                continue
                
            centerDisk = calculateDisks(point, p2)
            
            if centerDisk == []:
                continue
            
            nearestCenter = treeFrame.query_ball_point([centerDisk.x,centerDisk.y], (epsilon/2)+precision)
            members = []
            
            for k in nearestCenter:
                members.append(pointsFrame[k].id)
            
            if len(members) < mu:
                continue
            
            stdin += (str(members)+"\n")
    
    if stdin != '':
        output = open('outputDisk.dat','w')
        output.write(stdin)
        output.close()
        
def maximalDisksTimestamp(timestamp, diskID):
    """This method return the maximal disks per timestamp with LCM"""
    maximalDisks = {}
    maximalDisks[timestamp] = {}
    
    if os.path.exists('outputDisk.mfi'):
        os.system('rm outputDisk.mfi')
            
    os.system("./fim_maximal outputDisk.dat " + str(1) + " outputDisk.mfi > /dev/null")    
    
    output1 = open('outputDisk.mfi','r')
    lines = output1.readlines()
    for line in lines:
        lineSplit = line.split(' ')
        try:
            array = list(map(int,lineSplit[:-1]))
        except ValueError:
            lineSplit = line.split(' ')
            array = []
            for a in lineSplit:
                if a == '':
                    a = 0
                array.append(a)
            array = list(map(int,array[:-1]))
    
        maximalDisks[timestamp][diskID] = Disk(diskID, timestamp, set(array))
        diskID += 1    
    
    maximalDisks = maximalDisks[timestamp]
                    
    return (maximalDisks, diskID)
                
def main():
    global epsilon
    global mu
    global precision
            
    epsilon = 300 
    mu = 9
    precision = 0.001
    filename = 'SJ50K55.csv'
    
    dataset = csv.reader(open('Datasets/'+filename, 'r'),delimiter='\t')
    next(dataset)
    
    t1 = time.time()
    
    points = pointTimestamp(dataset)
    
    timestamps = list(map(int,points.keys()))
    timestamps.sort()
        
    diskID = 1
    
    for timestamp in timestamps:
        disksTimestamp(points, timestamp)
        if not os.path.exists('outputDisk.dat'):
            continue
        maximalDisks, diskID = maximalDisksTimestamp(timestamp, diskID)
        print("Maximal",len(maximalDisks))
                                    
    t2 = time.time() - t1    
    print("\nTime: ",t2)
    return 0

if __name__ == '__main__':
    main()

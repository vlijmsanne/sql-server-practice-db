IF DB_ID('PracticeDB') IS NULL
	CREATE DATABASE PracticeDB;
GO

USE PracticeDB;
GO

CREATE TABLE Customers (
	CustomerID INT IDENTITY(1,1) PRIMARY KEY,
	CustomerName VARCHAR(100) NOT NULL,
	Industry VARCHAR(50),
	IsActive BIT DEFAULT 1, 
	CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE DatabaseServers (
	ServerID INT IDENTITY(1,1) PRIMARY KEY,
	CustomerID INT NOT NULL,
	ServerName VARCHAR(100) NOT NULL,
	Environment VARCHAR(20) NOT NULL,
	Location VARCHAR(50),
	IsMonitored BIT DEFAULT 1,
	CreatedAt DATETIME DEFAULT GETDATE(),

	FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Databases (
	DatabaseID INT IDENTITY(1,1) PRIMARY KEY,
	ServerID INT NOT NULL,
	DatabaseName VARCHAR(100) NOT NULL,
	IsOnline BIT DEFAULT 1,
	SizeMB INT,
	CreatedAt DATETIME DEFAULT GETDATE(),

	FOREIGN KEY (ServerID) REFERENCES DatabaseServers(ServerID)
);

CREATE TABLE MonitoringChecks (
	CheckID INT IDENTITY(1,1) PRIMARY KEY,
	DatabaseID INT NOT NULL,
	CheckType VARCHAR(50) NOT NULL,
	CheckStatus VARCHAR(20) NOT NULL,
	CheckDate DATETIME DEFAULT GETDATE(),
	Message VARCHAR(255),

	FOREIGN KEY (DatabaseID) REFERENCES Databases(DatabaseID)
);

CREATE TABLE Incidents (
	IncidentID INT IDENTITY(1,1) PRIMARY KEY,
	DatabaseID INT NOT NULL,
	IncidentDate DATETIME DEFAULT GETDATE(),
	Severity VARCHAR(20) NOT NULL,
	Description VARCHAR(255) NOT NULL,
	IsResolved BIT DEFAULT 0,
	ResolvedAt DATETIME NULL,

	FOREIGN KEY (DatabaseID) REFERENCES Databases(DatabaseID)
);

INSERT INTO Customers (CustomerName, Industry)
VALUES ('Frion (demo)', 'Gehandicaptenzorg');

INSERT INTO DatabaseServers (CustomerID, ServerName, Environment, Location)
VALUES
(1, 'Frion-SQL-01', 'Production', 'Zwolle'),
(1, 'Frion-SQL-02', 'Test', 'Zwolle');

INSERT INTO Databases (ServerID, DatabaseName, SizeMB)
VALUES
(1, 'ClientRecordsDB', 12500),
(1, 'PlanningDB', 4200),
(2, 'ClientRecordsDB_Test', 3500),
(1, 'EmptyDB', 1000);

INSERT INTO MonitoringChecks (DatabaseID, CheckType, CheckStatus, Message)
VALUES 
(1, 'Backup', 'OK', 'Last backup completed successfully'),
(1, 'Disk Space', 'Warning', 'Disk usage above 80%'),
(2, 'Online Status', 'OK', 'Database is online'),
(3, 'Backup', 'Critical', 'No recent backup found'),
(2, 'Performance', 'Warning', 'High query latency detected');

INSERT INTO Incidents (DatabaseID, Severity, Description, IsResolved, ResolvedAt)
VALUES
(3, 'High', 'Backup check failed: no recent backup found', 0, NULL),
(1, 'Medium', 'Disk space warning resolved', 1, GETDATE()),
(2, 'High', 'Database performance issue detected', 0, NULL);

-- Validate inserted data
SELECT * FROM Customers;
SELECT * FROM DatabaseServers;
SELECT * FROM Databases;
SELECT * FROM MonitoringChecks;
SELECT * FROM Incidents;

-- Show databases with issues
SELECT
c.CustomerName,
s.ServerName,
s.Environment,
d.DatabaseName,
d.SizeMB,
m.CheckType,
m.CheckStatus,
m.Message,
m.CheckDate
FROM Customers AS c
JOIN DatabaseServers AS s ON c.CustomerID = s.CustomerID
JOIN Databases AS d ON s.ServerID = d.ServerID
JOIN MonitoringChecks AS m ON d.DatabaseID = m.DatabaseID
WHERE m.CheckStatus <> 'OK'
ORDER BY c.CustomerName, s.ServerName, d.DatabaseName, m.CheckDate DESC;

-- Show unresolved incidents per database
SELECT
	d.DatabaseName,
	i.Severity,
	i.Description,
	i.IncidentDate,
	i.IsResolved
FROM Incidents AS i
JOIN Databases AS d ON i.DatabaseID = d.DatabaseID
WHERE i.IsResolved = 0;

-- Count number of issues per server
SELECT
	s.ServerName,
	COUNT(*) AS IssueCount
FROM DatabaseServers AS s
JOIN Databases AS d ON s.ServerID = d.ServerID
JOIN MonitoringChecks AS m ON d.DatabaseID = m.DatabaseID
WHERE m.CheckStatus <> 'OK'
GROUP BY s.ServerName;

-- LEFT JOIN: Show all databases, including those without monitoring checks
SELECT
    d.DatabaseName,
    m.CheckStatus
FROM Databases d
LEFT JOIN MonitoringChecks m 
    ON d.DatabaseID = m.DatabaseID;
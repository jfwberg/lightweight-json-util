sf env create scratch --target-dev-hub=awsbpo --definition-file config/project-scratch-def.json --set-default --duration-days 10

sf data query --query "SELECT Name, (SELECT FirstName, LastName, Owner.Profile.Name FROM contacts LIMIT 10) FROM Account WHERE Name LIKE 'Demo Account - %' ORDER BY Name ASC LIMIT 1000" --json > data.json


#!/usr/bin/env python3
import os
import unittest
import snow_incident


class TestSnowIncident(unittest.TestCase):
    def test_get_env_settings(self):
        # Brittle test of environment variable handling
        stash = {}
        for e in snow_incident.REQUIRED_ENVARS:
            stash[e] = os.environ.pop(e)

        with self.assertRaises(ValueError):
            snow_incident.get_env_settings()

        inset = {
            "url": "https://servicelater.net",
            "default_body": {
                "category": "Ice Cream Truck",
                "assignment_group": "Mr Frosty",
                "item": "Issue",
                "subcategory": "Freezer",
            },
            "parameter_base": "/the/settings",
        }

        os.environ["SNOW_INCIDENT_URL"] = inset["url"]
        os.environ["SNOW_CATEGORY"] = inset["default_body"]["category"]
        os.environ["SNOW_SUBCATEGORY"] = inset["default_body"]["subcategory"]
        os.environ["SNOW_ASSIGNMENT_GROUP"] = inset["default_body"]["assignment_group"]
        os.environ["SNOW_PARAMETER_BASE"] = inset["parameter_base"]

        self.assertDictEqual(snow_incident.get_env_settings(), inset)

        for e in snow_incident.REQUIRED_ENVARS:
            if stash[e] is None:
                os.environ.pop(e)
            else:
                os.environ[e] = stash[e]

    def test_parse_event(self):
        event = {
            "Records": [
                {
                    "Sns": {
                        "Subject": "Whatever",
                        "Message": "It happened",
                        "Timestamp": "2021-12-25T00:00:00:00Z",
                    }
                }
            ]
        }

        self.assertDictEqual(
            snow_incident.parse_event(event),
            {
                "short_description": "Whatever",
                "description": "It happened",
                "timestamp": "2021-12-25T00:00:00:00Z",
                "priority": 2,
            },
        )

        event["Records"][0]["Sns"].pop("Subject")
        with self.assertRaises(KeyError):
            snow_incident.parse_event(event)

        event["Records"][0]["Sns"]["Subject"] = "Whatever [p5]"
        self.assertDictEqual(
            snow_incident.parse_event(event),
            {
                "short_description": "Whatever [p5]",
                "description": "It happened",
                "timestamp": "2021-12-25T00:00:00:00Z",
                "priority": 5,
            },
        )

        event["Records"][0]["Sns"]["Message"] = '{"fancy": "yeah!", "priority": 0}'
        self.assertDictEqual(
            snow_incident.parse_event(event),
            {
                "short_description": "Whatever [p5]",
                "description": "{\n  \"fancy\": \"yeah!\",\n  \"priority\": 0\n}",
                "timestamp": "2021-12-25T00:00:00:00Z",
                "priority": 0,
            },
        )

        event["Records"][0]["Sns"]["Message"] = '{"fancy": "yeah!", "priority": 10}'
        with self.assertRaises(ValueError):
            snow_incident.parse_event(event)


if __name__ == "__main__":
    unittest.main()

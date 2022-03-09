#!/usr/bin/env python3
import os
import unittest
import snow_incident


class TestSnowIncident(unittest.TestCase):
    def test_get_env_settings(self):
        # Brittle test of environment variable handling
        stash = {}
        for e in snow_incident.REQUIRED_ENVARS:
            stash[e] = os.environ.get(e)

        with self.assertRaises(ValueError):
            snow_incident.get_env_settings()

        inset = {
            "url": "https://servicelater.net",
            "default_body": {
                "contact_type": "API",
                "caller_id": "abcd1010",
                "u_category": "2340871320870dead",
                "u_subcategory": "23989823cafe2",
                "u_item": "34983498feed",
            },
            "parameter_base": "/the/settings",
        }

        os.environ["SNOW_INCIDENT_URL"] = inset["url"]
        os.environ["SNOW_CALLER_ID"] = inset["default_body"]["caller_id"]
        os.environ["SNOW_CATEGORY_ID"] = inset["default_body"]["u_category"]
        os.environ["SNOW_SUBCATEGORY_ID"] = inset["default_body"]["u_subcategory"]
        os.environ["SNOW_ITEM_ID"] = inset["default_body"]["u_item"]
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

import json
import sys

class DeepCodeToSarif:
  def tool(self):
    output = dict()
    output["driver"] = dict()
    output["driver"]["name"] = "DeepCode"

    rules = []
    for suggestion_order in self.deepcode_json["results"]["suggestions"]:
      severity = {
        3: "error",
        2: "warning",
        1: "note"
      }[self.deepcode_json["results"]["suggestions"][suggestion_order]["severity"]]
      sid = self.deepcode_json["results"]["suggestions"][suggestion_order]["id"]

      rules.append({
        "id": sid,
        "name": self.deepcode_json["results"]["suggestions"][suggestion_order]["rule"],
        "shortDescription": {
          "text": self.deepcode_json["results"]["suggestions"][suggestion_order]["message"]
        },
        "fullDescription": {
          "text": self.deepcode_json["results"]["suggestions"][suggestion_order]["message"]
        },
        "defaultConfiguration": {
          "level": severity,
        },
        "properties": {
          "tags": [sid.split("%2F")[0]],
          "precision": "very-high"
        }
      })

      self.suggestions[suggestion_order]["level"] = severity
      self.suggestions[suggestion_order]["id"] = sid
      self.suggestions[suggestion_order]["text"] = self.deepcode_json["results"]["suggestions"][suggestion_order]["message"]

    output["driver"]["rules"] = rules
    return output

  def results(self):
    output = []

    for suggestion in self.suggestions:
      result = {
        "ruleId": self.suggestions[suggestion]["id"],
        "level": self.suggestions[suggestion]["level"],
        "message": {
          "text": self.suggestions[suggestion]["text"]
        },
        "locations": [{
          "physicalLocation": {
            "artifactLocation": {
              "uri": self.suggestions[suggestion]["file"],
              "uriBaseId": "%SRCROOT%"
            },
            "region": {
              "startLine": self.suggestions[suggestion]["rows"][0],
              "endLine": self.suggestions[suggestion]["rows"][1],
              "startColumn": self.suggestions[suggestion]["cols"][0],
              "endColumn": self.suggestions[suggestion]["cols"][1]
            }
          }
        }]
      }

      code_thread_flows = []
      if len(self.suggestions[suggestion]["markers"]) > 1:
        i = 0
        for marker_positions in self.suggestions[suggestion]["markers"]:
          for position in marker_positions["pos"]:
            code_thread_flows.append(
              {
                "location": {
                  "physicalLocation": {
                    "artifactLocation": {
                      "uri": self.suggestions[suggestion]["file"],
                      "uriBaseId": "%SRCROOT%",
                      "index": i
                    },
                    "region": {
                      "startLine": position["rows"][0],
                      "endLine": position["rows"][1],
                      "startColumn": position["cols"][0],
                      "endColumn": position["cols"][1]
                    }
                  }
                }
              }
            )
            i = i + 1

      result["codeFlows"] = []
      result["codeFlows"].append(
        {
          "threadFlows": [
            {
              "locations": code_thread_flows
            }
          ]
        }
      )
      output.append(result)

    return output

  def convert_to_sarif(self):
    sarif_output = dict()
    sarif_output["$schema"] = "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json"
    sarif_output["version"] =  "2.1.0"
    sarif_output["runs"] = [
      {
        "tool": self.tool(),
        "results": self.results()
      }
    ]

    return sarif_output

  def __init__(self, deepcode_json):
    self.suggestions = dict()
    self.deepcode_json = deepcode_json

    for file in self.deepcode_json["results"]["files"]:
      for issue_id in self.deepcode_json["results"]["files"][file]:
        if issue_id not in self.suggestions:
          self.suggestions[issue_id] = self.deepcode_json["results"]["files"][file][issue_id][0]
          self.suggestions[issue_id]["file"] = file[1:]

if __name__ == "__main__":
    deepcode_json_file = sys.argv[1]
    dc_input = None

    with open(deepcode_json_file) as input_json:
      dc_input = json.load(input_json)

    with open('output.sarif', 'w') as outfile:
      json.dump(DeepCodeToSarif(dc_input).convert_to_sarif(), outfile)

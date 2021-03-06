import GitHub

auth = GitHub.authenticate(ENV["GITHUB_AUTH"])
repo = "vtjnash/julia"
sha = GitHub.branch(repo, "notmaster").commit.sha

message = """
          Executing the daily benchmark build, I will reply here when finished:

          @nanosoldier `runbenchmarks(ALL, isdaily = true)`
          """
GitHub.create_comment(repo, sha, :commit, auth=auth, params=Dict("body" => message))

message = """
          Executing the daily package evaluation, I will reply here when finished:

          @nanosoldier `runtests(ALL, isdaily = true)`
          """
GitHub.create_comment(repo, sha, :commit, auth=auth, params=Dict("body" => message))

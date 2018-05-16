Feature: GitHub user search
  In order to find the repositories of an user in GitHub
  As user
  I want to have a search box to introduce my keywords

  Scenario: can search using my keywords
    Given the search GitHub page loaded
    When I introduce my search keywords for an user in the search box
    And I press enter in the search box
    Then I should obtain a list of repositories for that user

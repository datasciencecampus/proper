# skeletor
## A Project Template for Data Science Campus Projects

### 1. Introduction

This repository is intended to provide you with the documents you need to
include to get a repository started and give guidance as to what the contents
should be. The minimum content contained in the README.md for your project
should be (in the most suitable order for the content):

- description of what the project is
- instruction on how to install the tool (if applicable)
- detailed instructions on basic use
- a demo of the code

With the inclusion of all documents included here, your repository should meet
all of the recommended [community standards on github.com](https://help.github.com/en/categories/building-a-strong-community).

Once you have copied this directory you should replace the content of this file
with the description of your work.

Whilst no mandatory recommendation is made as to how to
structure the directories or manage the project itself - as this will vary based
on the needs and the abilities of those doing the development work - guidelines
are provided below on how to conduct your project in an Agile manner.

If your project is complex enough to warrant a documentation website please add
a branch called `gh_pages` and place your documentation (in html format) there.
Once you do this your html files will be rendered at
https://datasciencecampus.github.io/projectName

### 2. Use

There are two ways to use this template:

#### 2.1. Using GitHub (simple method)

At the top of the main page of this repo is a green [Use this template](https://github.com/datasciencecampus/skeletor/generate) button, which
will clone this repository into a new repository of your choice. This will also copy over label templates.

#### 2.2. Using Git

Create your new repository with a suitable projectName.

Clone this template to the new repository using

``` sh
git clone git@github.com:datasciencecampus/skeletor projectName
```

which will then create a new directory with your project's name and place all of
the files into it. However, the remote address will remain as the skeletor repo
until you do

``` sh
git remote set-url origin git@github.com:datasciencecampus/projectName
```

### 3. Using GitHub for Project Management

All updates for a project must still be included in the relevant [issue on the main project kanban board](https://github.com/orgs/datasciencecampus/projects/21).
These guidelines relate to the project repository that you created using the above guidelines.

#### 3.1. Projects

This repository shows three projects in the [Project panel](https://github.com/datasciencecampus/skeletor/projects):
Discovery, Delivery and Dissemination. These projects are setup based on the Campus' project life-cycle and each use a kanban board
(To do, In Progress, Done). Issues (tasks) should be assigned to the relevant stage of the project life-cycle.

Setup a project board using the 'automated Kanban' template style for each.

#### 3.2. Issues

This GitHub template comes with four [Issue templates](https://github.com/datasciencecampus/skeletor/issues/new/choose):
Bug report, Feature request, Use query and Task. The first three are normally used when the repository and tool has been made public.

The [Task issue template](https://github.com/datasciencecampus/skeletor/issues/new?assignees=&labels=&template=task.md&title=)
should be used to create tasks during the project. Issues (tasks) can be created and assigned ad-hoc, or during stand-ups.

#### 3.3. Milestones

[GitHub Milestones](https://github.com/datasciencecampus/skeletor/milestones) can be used to assign tasks to a sprint cycle.
By assigning a task to a Project and a Milestone, progress on individual sprints as well as stages of the project life-cycle
can be viewed by the project manager and delivery manager. Milestones should be given due dates, and then all tasks assigned to this
milestone can be reviewed at the end of the sprint cycle.

#### 3.4. Labels

The [generic GitHub labels are limited in their use](https://medium.com/@dave_lunny/sane-github-labels-c5d2e6004b63),
this repository has additional [labels](https://github.com/datasciencecampus/skeletor/labels):

- Priority: Low
- Priority: Medium
- Priority: High
- Priority: Critical
- Project: Background Research
- Project: Data and Methods
- Project: Ethical Review
- Project: Stakeholder Engagement
- Project: Technical Plan
- Status: Abandoned
- Status: Accepted
- Status: Available
- Status: Blocked
- Status: Completed
- Status: In Progress
- Status: On Hold
- Status: Pending
- Status: Review Needed
- Status: Revision Needed
- Type: Bug
- Type: Maintenance
- Type: Enhancement
- Type: Question

To setup these labels do the following:

```
npm i -g git-labelmaker
cd projectName
git-labelmaker
```

Then go to 'Add labels from package' and then type:

```
packages/custom-labels.json
```

The 'Project' labels encompass the majority of Discovery tasks. However, add more labels if you need (either manually or to the JSON file).
Whereas Issues are small, manageable tasks, Labels are meant to be broad. Using labels shows where the
majority of the time is being spent on projects by the project manager and delivery manager.

#### 3.5. Example

For a new project, first clone this repository using the steps in section 2. Then setup the three stages
of the project life cycle as described in section 3.2, and then add the first sprint as a milestone (section 3.3).
Next, to add the custom labels, follow the steps in section 3.4. Then begin to add tasks.

The first task in the Discovery phase may be to ask within the Campus' whether anyone has done any similar
or relevant work in the past. Therefore setup an Issue using the [Task template](https://github.com/datasciencecampus/skeletor/issues/new?assignees=&labels=&template=task.md&title=), which may be titled 'Ask within Campus about previous relevant work'.
Assign this task to the relevant person, add the label of 'Project: Background Research',
assign to the project 'Discovery' and assign to Sprint 1 in the Milestone section.

Once this task has been completed, close this Issue. The closure of this Issue will then increase
the progress bar on both the Milestone and Project.

#### 3.6. Benefits

- This will aid delivery and project managers to see the progress of projects in the project life-cycle
- a comprehensive use of an 'issue' in GitHub will allow delivery and project managers to filter tasks to assign additional resource
- use of the projects board for each stage of the life-cycle will allow users to quickly see what stage a project is in
- it facilitates agile working in sprints

### 4. Contents

* **CODE_OF_CONDUCT.md**: a statement from the [Contributor
  Covenant](https://contributor-covenant.org) regarding what is and isn't
  acceptable behaviour for contributors
* **CONTRIBUTING**: guidelines for how contributions should be made to the work,
  this is currently empty but should contain information such as code
  formatting, how to add test fixes and how to submit patches. There is a very
  good
  [example](https://github.com/puppetlabs/puppet/blob/master/CONTRIBUTING.md)
  from the puppet repo by puppetlabs. Because all of our teams will be varied in
  terms of size, skills and project aims it is left to each project to define
  this.
* **README.md**: this document, every repository should have one and it acts as
  the main landing page for your repository
* **LICENSE**: the UK public sector usually operate under two different
  licensing schemes. The most common for code is the MIT license which is
  included in this repo. Alternatively there is an Open Government license and
  a description of what OpenGov enforces can be found
  [here](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
* **.github**: this directory allows the user to specify templates for
  contribution types, included in this repository are a bug fix submission
  template, a feature request template and a pull request template. Each of them
  includes a series of tickboxes which you can use to help you decide whether or
  not the submission is suitable.
* **.gitignore**: this file allows you to specify which directories, files and
  globbed file types are to be ignored as part of the diffs being managed by
  git. This allows you to have your data in the same directory structure as your
  code without it needing to be pushed and pulled along with it. If you have
  data which you do need to manage I would highly advise the use of `git-annex`
  ahead of including data files in your repository (unless they are small).

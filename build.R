library(devtools)
library(knitr)


# compile Readme
knit("README.Rmd", "README.md")

document("pkg")
test("pkg")
check("pkg")

build("pkg")



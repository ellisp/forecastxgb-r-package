library(devtools)
library(knitr)


# compile Readme
knit("README.Rmd", "README.md")
test("pkg")

document("pkg")
check("pkg")
build_vignettes("pkg")
build("pkg")


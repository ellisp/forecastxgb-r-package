library(devtools)
library(knitr)


# compile Readme
knit("README.Rmd", "README.md")
test("pkg")


document("pkg")
build_vignettes("pkg")
check("pkg")
build("pkg")


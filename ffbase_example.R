## Example as seen on https://rpubs.com/demydd/235941

# Load required libraries
library(ff)
library(ffbase)

# Make the initial data frame and show it's size
df_size <- 50000000
x <- data.frame(a = numeric(df_size), b = numeric(df_size), c = numeric(df_size))
print(paste(round(object.size(x)/1024/1024,2),"Mb")) 
# Expected size is high

# Convert to ffdf object and show it's size
x1<-as.ffdf(x)
print(paste(round(object.size(x1)/1024/1024,2),"Mb"))
# Expected size to be smaler than that of the normal x.

# Remove the objects to save some RAM :)
rm(x)
rm(x1)

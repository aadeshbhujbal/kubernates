from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from delta.tables import *

def create_spark_session():
    return (SparkSession.builder
            .appName("KafkaToDelta")
            .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
            .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
            .config("spark.databricks.delta.retentionDurationCheck.enabled", "false")
            .getOrCreate())

def process_stream():
    spark = create_spark_session()
    
    # Read from Kafka
    kafka_df = (spark
                .readStream
                .format("kafka")
                .option("kafka.bootstrap.servers", "kafka:29092")
                .option("subscribe", "transactions")
                .load())
    
    # Process data
    processed_df = (kafka_df
                   .selectExpr("CAST(value AS STRING)")
                   .select(from_json(col("value"), schema).alias("data"))
                   .select("data.*"))
    
    # Write to Delta Lake
    query = (processed_df
            .writeStream
            .format("delta")
            .outputMode("append")
            .option("checkpointLocation", "/tmp/checkpoint")
            .start("/data/delta/transactions"))
    
    query.awaitTermination()

if __name__ == "__main__":
    process_stream() 